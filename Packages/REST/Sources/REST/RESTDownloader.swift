//
//  RESTDownloader.swift
//
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation

extension REST {
	public class Downloader: NSObject, URLSessionDownloadDelegate {
		public enum ResultState {
			case cancelled
			case progress(currentBytes: Double, totalBytes: Double)
			case success(url: URL)
			case failed(error: Error)
		}

		private static var identifier: String = "io.lucaa.Loadle.DownloadManager"
		private static var dir = "DOWNLOADS"
		
		private var downloads: [URL: Download] = [:]
		private var backgroundCompletionHandlers: [() -> Void] = []

		public var debuggingBackroundTasks: Bool {
			#if DEBUG
			return true
			#else
			return false
			#endif
		}

		private lazy var downloadSession: URLSession = {
			let config = URLSessionConfiguration.background(withIdentifier: Self.identifier)
			config.sessionSendsLaunchEvents = true
			config.allowsCellularAccess = true
			return URLSession(configuration: config, delegate: self, delegateQueue: .main)
		}()

		public static var shared = REST.Downloader()

		private override init() {
			super.init()

			if debuggingBackroundTasks {
				URLSession.shared.invalidateAndCancel()
			}
		}

		public static func loadDownloadsURL() throws -> URL {
			let downloadsURL = try FileManager.default
				.url(for: .documentDirectory,
					 in: .userDomainMask,
					 appropriateFor: nil,
					 create: false)
				.appending(component: Self.dir, directoryHint: .isDirectory)

			if !FileManager.default.fileExists(atPath: downloadsURL.standardized.path(percentEncoded: false)) {
				try FileManager.default.createDirectory(at: downloadsURL, withIntermediateDirectories: true, attributes: nil)
			}
			return downloadsURL
		}

		public func download(url: URL, onStateChange: @escaping (ResultState) -> Void) {
			let download = Download(session: downloadSession, url: url, completionHandler: onStateChange)
			downloads[url] = download
			download.resume()
		}

		public func deleteDownload(with url: URL) {
			downloads[url]?.cancel()
			downloads.removeValue(forKey: url)
		}

		public func cancelDownload(with url: URL) {
			downloads[url]?.pause()
		}

		public func resumeDownload(with url: URL) {
			downloads[url]?.resume()
		}

		public func addBackgroundCompletionHandler(handler: @escaping () -> Void) {
			backgroundCompletionHandlers.append(handler)
		}

		public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
			guard let url = downloadTask.originalRequest?.url else { return }
			downloads[url]?.updateProgress(currentBytes: totalBytesWritten, totalBytes: totalBytesExpectedToWrite)
		}

		public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
			guard let url = downloadTask.originalRequest?.url else { return }
			let newFilename = downloadTask.response?.suggestedFilename ?? UUID().uuidString
			do {
				let downloadURL = try Self.loadDownloadsURL()
					.appending(component: newFilename, directoryHint: .notDirectory)
				try FileManager.default.moveItem(at: location, to: downloadURL)
				downloads[url]?.complete(with: downloadURL)
				downloads[url] = nil
			} catch {
				downloads[url]?.complete(with: error)
			}
		}

		public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
			guard let error, let url = task.originalRequest?.url else { return }
			downloads[url]?.complete(with: error)
		}

		public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
			guard let url = downloadTask.originalRequest?.url else { return }
			downloads[url]?.updateProgress(currentBytes: fileOffset, totalBytes: expectedTotalBytes)
		}

		public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
			DispatchQueue.main.async {
				self.backgroundCompletionHandlers.forEach { $0() }
				self.backgroundCompletionHandlers = []
			}
		}
	}

	fileprivate class Download: NSObject {
		fileprivate enum State: String {
			case ready
			case downloading
			case paused
			case cancelled
			case completed
		}

		private let session: URLSession
		private var downloadTask: URLSessionDownloadTask?
		private var resumedData: Data?

		private let url: URL
		private let completionHandler: (Downloader.ResultState) -> Void

		private(set) var state: State = .ready

		var isCoalescable: Bool {
			return (state == .ready) ||
			(state == .downloading) ||
			(state == .paused)
		}

		var isResumable: Bool {
			return (state == . ready) ||
			(state == .paused)
		}

		var isPaused: Bool {
			return state == .paused
		}

		var isCompleted: Bool {
			return state == .completed
		}

		init(session: URLSession, url: URL, completionHandler: @escaping (Downloader.ResultState) -> Void) {
			self.session = session
			self.url = url
			self.completionHandler = completionHandler
		}

		fileprivate func resume() {
			state = .downloading

			if let resumedData = resumedData {
				downloadTask = session.downloadTask(withResumeData: resumedData)
			} else {
				downloadTask = session.downloadTask(with: url)
			}

			downloadTask?.resume()
		}

		fileprivate func cancel() {
			state = .cancelled

			downloadTask?.cancel()

			cleanup()
		}

		fileprivate func pause() {
			state = .paused

			downloadTask?.cancel(byProducingResumeData: { [weak self] resumedData in
				guard let self else { return }
				defer {
					self.cleanup()
					self.completionHandler(.cancelled)
				}

				guard let resumedData else { return }
				self.resumedData = resumedData
			})
		}

		fileprivate func complete(with newFileLocation: URL) {
			defer {
				if state != .paused {
					state = .completed
				}

				cleanup()
			}

			completionHandler(.success(url: newFileLocation))
		}

		fileprivate func complete(with error: Error) {
			defer {
				if state != .paused {
					state = .completed
				}

				cleanup()
			}

			completionHandler(.failed(error: error))
		}

		fileprivate func updateProgress(currentBytes: Int64, totalBytes: Int64) {
			completionHandler(.progress(currentBytes: Double(currentBytes), totalBytes: Double(totalBytes)))
		}

		private func cleanup() {
			downloadTask = nil
		}
	}
}
