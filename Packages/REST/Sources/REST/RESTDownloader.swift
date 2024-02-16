//
//  RESTDownloader.swift
//
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation

extension REST {
	public class Downloader: NSObject, URLSessionDownloadDelegate {
		fileprivate class DownloaderStore {
			private let queue = DispatchQueue(label: "REST.Downloader.Store")
			private var downloads: [URL: Download] = [:]

			func add(new download: Download, using url: URL) {
				queue.sync {
					downloads[url] = download
				}
			}

			func cancel(using url: URL) {
				queue.sync {
					downloads[url]?.pause()
				}
			}

			func delete(using url: URL) {
				queue.sync {
					downloads[url]?.cancel()
					downloads.removeValue(forKey: url)
				}
			}

			func resume(using url: URL) {
				queue.sync {
					downloads[url]?.resume()
				}
			}

			func updateProgress(using url: URL, currentBytes: Int64, totalBytes: Int64) {
				queue.sync {
					downloads[url]?.updateProgress(currentBytes: currentBytes, totalBytes: totalBytes)
				}
			}

			func complete(using url: URL, newFileLocation: URL) {
				queue.sync {
					downloads[url]?.complete(with: newFileLocation)
					downloads[url] = nil
				}
			}

			func complete(using url: URL, error: Error) {
				queue.sync {
					downloads[url]?.complete(with: error)
					downloads[url] = nil
				}
			}
		}

		public enum ResultState {
			case cancelled
			case progress(currentBytes: Double, totalBytes: Double)
			case success(url: URL)
			case failed(error: Error)
		}

		private static var identifier: String = "io.lucaa.Loadle.DownloadManager"
		
		private var downloads: [URL: Download] = [:]

		public var backgroundCompletionHandler: (() -> Void)?

		private let debuggingBackroundTasks: Bool
		private let store: DownloaderStore = DownloaderStore()

		private lazy var downloadSession: URLSession = {
			let config = URLSessionConfiguration.background(withIdentifier: Self.identifier)
			config.sessionSendsLaunchEvents = true
			config.allowsCellularAccess = true
			return URLSession(configuration: config, delegate: self, delegateQueue: .main)
		}()

		public static func shared(withDebuggingBackgroundTasks: Bool = false) -> REST.Downloader {
			return REST.Downloader(debuggingBackroundTasks: withDebuggingBackgroundTasks)
		}
		
		private init(debuggingBackroundTasks: Bool = false) {
			self.debuggingBackroundTasks = debuggingBackroundTasks

			super.init()

			if debuggingBackroundTasks {
				URLSession.shared.invalidateAndCancel()
			}
		}

		public func download(url: URL, onStateChange: @escaping (ResultState) -> Void) {
			let download = Download(session: downloadSession, url: url, completionHandler: onStateChange)
			store.add(new: download, using: url)
			download.resume()
		}

		public func deleteDownload(with url: URL) {
			store.delete(using: url)
		}

		public func cancelDownload(with url: URL) {
			store.cancel(using: url)
		}

		public func resumeDownload(with url: URL) {
			store.resume(using: url)
		}

		public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
			guard let url = downloadTask.originalRequest?.url else { return }
			store.updateProgress(using: url, currentBytes: totalBytesWritten, totalBytes: totalBytesExpectedToWrite)
		}

		public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
			guard let url = downloadTask.originalRequest?.url else { return }
			let newFilename = downloadTask.response?.suggestedFilename ?? UUID().uuidString
			do {
				let downloadURL = location
					.deletingLastPathComponent()
					.appending(component: newFilename, directoryHint: .notDirectory)
				try FileManager.default.moveItem(at: location, to: downloadURL)
				store.complete(using: url, newFileLocation: downloadURL)
			} catch {
				store.complete(using: url, error: error)
			}
		}

		public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
			guard let error, let url = task.originalRequest?.url else { return }
			store.complete(using: url, error: error)
		}

		public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
			guard let url = downloadTask.originalRequest?.url else { return }
			store.updateProgress(using: url, currentBytes: fileOffset, totalBytes: expectedTotalBytes)
		}

		public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
			DispatchQueue.main.async {
				self.backgroundCompletionHandler?()
				self.backgroundCompletionHandler = nil
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
