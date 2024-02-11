//
//  RESTDownloader.swift
//
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation

extension REST {
	public class Downloader: NSObject, URLSessionDownloadDelegate {
		private static var identifier: String = "io.lucaa.Loadle.DownloadManager"
		private static var dir = "DOWNLOADS"
		
		private var downloads: [URL: Download] = [:]
		private var backgroundCompletionHandler: (() -> Void)?

		private lazy var downloadSession: URLSession = {
			let config = URLSessionConfiguration.background(withIdentifier: Self.identifier)
			config.sessionSendsLaunchEvents = true
			config.allowsCellularAccess = true
			return URLSession(configuration: config, delegate: self, delegateQueue: .main)
		}()

		public static var shared = REST.Downloader()

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

		public func download(url: URL, onStateChange: @escaping (REST.Download.State) -> Void) {
			let task = downloadSession.downloadTask(with: url)
			let download = Download(task: task, onStateChange: onStateChange)
			downloads[url] = download
			download.start()
		}

		public func deleteDownload(with url: URL) {
			downloads[url]?.finish()
			downloads.removeValue(forKey: url)
		}

		public func pauseDownload(with url: URL) {
			downloads[url]?.pause()
		}

		public func resumeDownload(with url: URL) {
			downloads[url]?.resume()
		}

		public func addBackgroundCompletionHandler(handler: @escaping () -> Void) {
			backgroundCompletionHandler = handler
		}

		public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
			guard let url = downloadTask.originalRequest?.url else { return }
			downloads[url]?.onStateChange(
				.progress(
					currentBytes: Double(totalBytesWritten),
					totalBytes: Double(totalBytesExpectedToWrite)))
		}

		public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
			guard let url = downloadTask.originalRequest?.url else { return }
			let newFilename = downloadTask.response?.suggestedFilename ?? UUID().uuidString
			do {
				let downloadURL = try Self.loadDownloadsURL()
					.appending(component: newFilename, directoryHint: .notDirectory)
				try FileManager.default.moveItem(at: location, to: downloadURL)
				downloads[url]?.onStateChange(.success(url: downloadURL))
				downloads[url] = nil
			} catch {
				downloads[url]?.onStateChange(.failed(error: error))
			}
		}

		public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
			guard let error, let url = task.originalRequest?.url else { return }
			downloads[url]?.onStateChange(.failed(error: error))
			downloads[url]?.finish()
		}

		public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
			DispatchQueue.main.async {
				self.backgroundCompletionHandler?()
				self.backgroundCompletionHandler = nil
			}
		}
	}

	public class Download: NSObject {
		public enum State {
			case progress(currentBytes: Double, totalBytes: Double)
			case success(url: URL)
			case paused
			case failed(error: Error)
			case pending
		}

		private let task: URLSessionDownloadTask
		private var prevState: State = .pending
		private var currentState: State = .pending {
			didSet {
				prevState = oldValue
			}
		}
		let onStateChange: (State) -> Void

		init(task: URLSessionDownloadTask, onStateChange: @escaping (State) -> Void) {
			self.task = task
			self.onStateChange = onStateChange
		}

		deinit { finish() }

		var isDownloading: Bool {
			task.state == .running
		}

		func update(state: State) {
			currentState = state
		}

		func start() {
			task.resume()
		}

		func pause() {
			onStateChange(.paused)
			task.suspend()
		}

		func resume() {
			task.resume()
		}

		func finish() {
			task.cancel()
		}
	}
}
