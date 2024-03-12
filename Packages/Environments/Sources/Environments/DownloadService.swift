//
//  DownloadService.swift
//  Loadle
//
//  Created by Luca Archidiacono on 14.02.2024.
//

import Foundation
import LinkPresentation
import Logger
import Models
import LocalStorage

private struct WrappedDownload {
	let item: DownloadItem
	let task: DownloadTask
}

private class DownloadTask: NSObject {
	private enum State: String {
		case ready
		case downloading
		case paused
		case cancelled
	}

	private let session: URLSession
	private var downloadTask: URLSessionDownloadTask?
	private var resumedData: Data?
	private var state: State = .ready

	var isResumable: Bool {
		return (state == .ready) || (state == .paused)
	}

	var isPaused: Bool {
		return state == .paused
	}

	public let url: URL

	fileprivate init(downloadTask: URLSessionDownloadTask? = nil, session: URLSession, url: URL) {
		self.downloadTask = downloadTask
		self.session = session
		self.url = url

		super.init()
	}

	public func resume() {
		state = .downloading

		if let resumedData = resumedData {
			downloadTask = session.downloadTask(withResumeData: resumedData)
		} else {
			downloadTask = session.downloadTask(with: url)
		}
		downloadTask?.resume()
	}

	public func cancel() {
		state = .cancelled

		downloadTask?.cancel()
		cleanup()
	}

	public func pause() async {
		state = .paused

		resumedData = await downloadTask?.cancelByProducingResumeData()
		cleanup()
	}

	private func cleanup() {
		downloadTask = nil
	}
}

private class URLSessionDownloadDelegateWrapper: NSObject, URLSessionDownloadDelegate {
	enum State {
		case cancelled
		case progress(currentBytes: Int64, totalBytes: Int64)
		case success(url: URL)
		case failed(error: Error)
	}

	var onUpdate: ((URLSessionDownloadTask, State) -> Void)?
	var onComplete: (() -> Void)?

	public func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		onUpdate?(downloadTask, .progress(currentBytes: totalBytesWritten, totalBytes: totalBytesExpectedToWrite))
	}

	public func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		let newFilename = downloadTask.response?.suggestedFilename ?? UUID().uuidString
		do {
			let downloadURL = location
				.deletingLastPathComponent()
				.appending(component: newFilename, directoryHint: .notDirectory)
			if FileManager.default.fileExists(atPath: downloadURL.standardizedFileURL.path(percentEncoded: false)) {
				try FileManager.default.removeItem(at: downloadURL)
			}
			try FileManager.default.moveItem(at: location, to: downloadURL)
			onUpdate?(downloadTask, .success(url: downloadURL))
		} catch {
			onUpdate?(downloadTask, .failed(error: error))
		}
	}

	public func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard let error, let downloadTask = task as? URLSessionDownloadTask else { return }
		if let urlError = error as NSError?, urlError.code == NSURLErrorCancelled {
			onUpdate?(downloadTask, .cancelled)
		} else {
			onUpdate?(downloadTask, .failed(error: error))
		}
	}

	public func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
		onUpdate?(downloadTask, .progress(currentBytes: fileOffset, totalBytes: expectedTotalBytes))
	}

	public func urlSessionDidFinishEvents(forBackgroundURLSession _: URLSession) {
		DispatchQueue.main.async {
			self.onComplete?()
		}
	}
}

private actor DownloadStore {
	private let urlSession: URLSession
	private var store: [URL: WrappedDownload] = [:] {
		didSet {
			downloadsContinuation?.yield(store.values.map { $0.item })
		}
	}
	private var downloadsContinuation: AsyncStream<[DownloadItem]>.Continuation?
	public lazy var downloads: AsyncStream<[DownloadItem]> = {
		AsyncStream { (continuation: AsyncStream<[DownloadItem]>.Continuation) -> Void in
			self.downloadsContinuation = continuation
		}
	}()

	init(urlSession: URLSession) {
		self.urlSession = urlSession
	}

	public func add(using remoteURL: URL, streamURL: URL, mediaService: MediaService, metadata: LPLinkMetadata) async {
		let downloadItem = DownloadItem(remoteURL: remoteURL, streamURL: streamURL, service: mediaService, metadata: metadata)
		let downloadTask = DownloadTask(session: urlSession, url: streamURL)
		let wrappedDownload = WrappedDownload(item: downloadItem, task: downloadTask)
		store[wrappedDownload.item.streamURL] = WrappedDownload(item: downloadItem, task: downloadTask)
		await PersistenceController.shared.downloadItem.store(downloadItem: downloadItem)
		downloadTask.resume()
	}

	public func delete(using url: URL) async {
		log(.verbose, "Is deleting Download.")
		guard let wrappedDownload = store[url] else {
			log(.warning, "Was not able to find and delete Download with url: \(url)")
			return
		}
		wrappedDownload.task.cancel()
		store.removeValue(forKey: url)
		await PersistenceController.shared.downloadItem.delete(wrappedDownload.item.id)
		log(.verbose, "Deleted Download successfully.")
	}

	public func cancel(using url: URL) async {
		log(.verbose, "Is cancelling Download.")
		guard let wrappedDownload = store[url] else {
			log(.warning, "Was not able to find and cancel Download with url: \(url)")
			return
		}

		guard !wrappedDownload.task.isPaused else { return }

		await wrappedDownload.task.pause()
		log(.verbose, "Cancelled download successfully.")
	}

	public func resume(using url: URL) async {
		log(.verbose, "Is resuming Download.")
		guard let wrappedDownload = store[url] else {
			log(.warning, "Was not able to find and resume Download with url: \(url)")
			return
		}

		guard wrappedDownload.task.isResumable else { return }

		wrappedDownload.task.resume()
		log(.verbose, "Resumed download successfully.")
	}

	public func update(using task: URLSessionDownloadTask, newState: URLSessionDownloadDelegateWrapper.State) async {
		guard let url = task.originalRequest?.url else { return }
		
		log(.verbose, "New state \(newState) received for url: \(url)")

		guard let downloadItem = await PersistenceController.shared.downloadItem.load(url) else {
			log(.warning, "Was not able to find and update `DownloadItem` with url: \(url)")
			return
		}

		var currentWrappedDownload: WrappedDownload

		if let wrappedDownload = store[url] {
			currentWrappedDownload = wrappedDownload
		} else {
			let downloadTask = DownloadTask(downloadTask: task, session: urlSession, url: url)
			currentWrappedDownload = WrappedDownload(item: downloadItem, task: downloadTask)
			store[url] = currentWrappedDownload
		}

		switch newState {
		case let .progress(currentBytes, totalBytes):
			log(.verbose, "New progress update: (current: \(currentBytes), total: \(totalBytes))")
			let updatedDownloadItem = currentWrappedDownload.item.update(state: .progress(currentBytes: Double(currentBytes), totalBytes: Double(totalBytes)))
			
			store[url] = WrappedDownload(item: updatedDownloadItem, task: currentWrappedDownload.task)

			await PersistenceController.shared.downloadItem.store(downloadItem: updatedDownloadItem)
		case let .success(fileURL):
			log(.info, "Successfully downloaded the media: \(fileURL)")
			
			store.removeValue(forKey: url)

			await PersistenceController.shared.downloadItem.delete(url)
			await MediaAssetService.shared.store(downloadItem: downloadItem, originalFileURL: fileURL)
		case let .failed(error):
			log(.error, "The download failed due to the following error: \(error)")
			let updatedDownloadItem = downloadItem.update(state: .failed)

			store[url] = WrappedDownload(item: updatedDownloadItem, task: currentWrappedDownload.task)

			await PersistenceController.shared.downloadItem.store(downloadItem: updatedDownloadItem)
		case .cancelled:
			log(.warning, "Download has been cancelled with following url: \(url)")
			let updatedDownloadItem = downloadItem.update(state: .cancelled)

			store[url] = WrappedDownload(item: updatedDownloadItem, task: currentWrappedDownload.task)

			await PersistenceController.shared.downloadItem.store(downloadItem: updatedDownloadItem)
		}
	}
}

public class DownloadService: NSObject {
	private static var identifier: String = "io.lucaa.Environment.Service.Download"
	
	private let delegate: URLSessionDownloadDelegateWrapper = URLSessionDownloadDelegateWrapper()
	private let store: DownloadStore
	private let downloadSession: URLSession

	private var backgroundCompletionHandlers: [() -> Void] = []
	private var stateContinuation: AsyncStream<(URLSessionDownloadTask, URLSessionDownloadDelegateWrapper.State)>.Continuation?
	private lazy var states: AsyncStream<(URLSessionDownloadTask, URLSessionDownloadDelegateWrapper.State)> = {
		AsyncStream(bufferingPolicy: .bufferingNewest(1)) { (continuation: AsyncStream<(URLSessionDownloadTask, URLSessionDownloadDelegateWrapper.State)>.Continuation) -> Void in
			self.delegate.onUpdate = { (task, newState) in
				continuation.yield((task, newState))
			}
			self.stateContinuation = continuation
		}
	}()

    public static let shared = DownloadService()

	public override init() {
		let config = URLSessionConfiguration.background(withIdentifier: Self.identifier)
		config.sessionSendsLaunchEvents = true
		config.allowsCellularAccess = true
		self.downloadSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
		self.store = DownloadStore(urlSession: downloadSession)

		super.init()

		Task.detached(priority: .background) {
			for await (task, newState) in self.states {
				await self.store.update(using: task, newState: newState)
			}
		}

		delegate.onComplete = { [weak self] in
			self?.backgroundCompletionHandlers.forEach { $0() }
			self?.backgroundCompletionHandlers = []
		}
	}

	public func download(using remoteURL: URL, streamURL: URL, mediaService: MediaService, metadata: LPLinkMetadata) async {
		await store.add(using: remoteURL, streamURL: streamURL, mediaService: mediaService, metadata: metadata)
	}

	public func downloads() async -> AsyncStream<[DownloadItem]> {
		await store.downloads
	}

	private var _deleteTasks: [URL: Task<Void, Never>] = [:]
	public func delete(using url: URL) {
		guard _deleteTasks[url] == nil else { return }

		Task(priority: .userInitiated) {
			_deleteTasks[url] = Task {
				await store.delete(using: url)
			}

			await _deleteTasks[url]?.value
			_deleteTasks[url] = nil
		}
	}

	private var _cancelTasks: [URL: Task<Void, Never>] = [:]
	public func cancel(using url: URL) {
		guard _cancelTasks[url] == nil else { return }

		Task(priority: .userInitiated) {
			_cancelTasks[url] = Task {
				await store.cancel(using: url)
			}
			await _cancelTasks[url]?.value
			_cancelTasks[url] = nil
		}
	}

	private var _resumeTasks: [URL: Task<Void, Never>] = [:]
	public func resume(using url: URL) {
		guard _resumeTasks[url] == nil else { return }

		Task(priority: .userInitiated) {
			_resumeTasks[url] = Task {
				await store.resume(using: url)
			}
			await _resumeTasks[url]?.value
			_resumeTasks[url] = nil
		}
	}

	public func addBackgroundCompletionHandler(completion: @escaping () -> Void) {
		backgroundCompletionHandlers.append(completion)
	}
}
