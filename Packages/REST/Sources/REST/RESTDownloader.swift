//
//  RESTDownloader.swift
//
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation
import Logger

extension REST {
	public class DownloadTask: Identifiable {
		public enum State {
			case pending
			case inProgress
			case completed
			case failed
			case canceled
		}

		public var id: Int { downloadTask.taskIdentifier }
		
		public var url: URL
		public var onComplete: ((Result<URL, Error>) -> Void)?
		public var onProgress: ((Double) -> Void)?

		fileprivate var onResumeCancelled: ((Data) -> URLSessionDownloadTask)?
		fileprivate var _onCancel: ((Bool) -> Void)?

		private var downloadTask: URLSessionDownloadTask
		private var resumedData: Data?

		public var state: State = .pending

		private let lock = NSLock()

		init(url: URL, downloadTask: URLSessionDownloadTask) {
			self.url = url
			self.downloadTask = downloadTask
		}

		public func cancel() {
			lock.lock()

			defer { lock.unlock() }

			downloadTask.cancel { resumedData in
				guard let resumedData = resumedData else {
					self.state = .failed
					self._onCancel?(false)
					return
				}
				self.resumedData = resumedData
				self.state = .canceled
				self._onCancel?(true)
			}
		}

		public func resumeCanceled() {
			lock.lock()

			defer { lock.unlock() }

			guard let resumedData, let onResumeCancelled else { return }

			self.downloadTask = onResumeCancelled(resumedData)
		}
	}

	public class Downloader: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
		private let taskStore = DownloadTaskStore()
		private let operationsQueue = OperationQueue()

		private static var identifier: String = "io.lucaa.Loadle.Background"

		private lazy var urlSession: URLSession = {
			let config = URLSessionConfiguration.background(withIdentifier: Self.identifier)
			config.isDiscretionary = true
			config.sessionSendsLaunchEvents = true
			return URLSession(configuration: config, delegate: self, delegateQueue: operationsQueue)
		}()

		public var allTasks: [DownloadTask] {
			return taskStore.getAllTasks()
		}

		public func startDownload(using request: REST.HTTPRequest, onComplete: (Result<DownloadTask, Error>) -> Void) {
			guard let url = request.url else {
				// we couldn't construct a proper URL out of the request's URLComponents
				onComplete(.failure(REST.HTTPError(code: .invalidRequest, request: request, response: nil, underlyingError: nil)))
				return
			}

			// construct the URLRequest
			var urlRequest = URLRequest(url: url)
			urlRequest.httpMethod = request.method.rawValue

			// copy over any custom HTTP headers
			for (header, value) in request.headers {
				urlRequest.addValue(value, forHTTPHeaderField: "\(header)")
			}

			if request.body.isEmpty == false {
				// if our body defines additional headers, add them
				for (header, value) in request.body.additionalHeaders {
					urlRequest.addValue(value, forHTTPHeaderField: header)
				}

				// attempt to retrieve the body data
				do {
					urlRequest.httpBodyStream = try request.body.encode()
				} catch {
					// something went wrong creating the body; stop and report back
					onComplete(.failure(REST.HTTPError(code: .invalidRequest, request: request, response: nil, underlyingError: nil)))
					return
				}
			}

			let task = urlSession.downloadTask(with: urlRequest)
			task.resume()
			let downloadTask = DownloadTask(url: url, downloadTask: task)
			taskStore.addNewTask(task: downloadTask)

			downloadTask._onCancel = { resumable in
				if !resumable {
					self.taskStore.removeTask(task: downloadTask)
				}
			}

			downloadTask.onResumeCancelled = { resumedData in
				let task = self.urlSession.downloadTask(withResumeData: resumedData)
				task.resume()
				self.taskStore.updateTaskIdentifier(oldIdentifier: downloadTask.id, newIdentifier: task.taskIdentifier)
				return task
			}

			onComplete(.success(downloadTask))
		}

		public func addBackgroundDownloadHandler(handler: @escaping () -> Void, identifier: String) {
			taskStore.addBackgroundDownloadHandler(handler: handler, identifier: identifier)
		}

		public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
			do {
				let documentsURL = try
				FileManager.default.url(for: .documentDirectory,
										in: .userDomainMask,
										appropriateFor: nil,
										create: false)
				let savedURL = documentsURL.appendingPathComponent(location.lastPathComponent)
				try FileManager.default.moveItem(at: location, to: savedURL)
				taskStore.finish(downloadingTo: savedURL, identifier: downloadTask.taskIdentifier)
			} catch {
				log(.error, error)
			}
		}

		public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
			let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
			taskStore.update(progress: progress, identifier: downloadTask.taskIdentifier)
		}

		public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
			if let identifier = session.configuration.identifier, !identifier.isEmpty {
				taskStore.finishAllEvents(identifier: identifier)
			}
		}

		public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
			guard let error else { return }
			taskStore.finish(withError: error, identifier: task.taskIdentifier)
		}
	}

	fileprivate class DownloadTaskStore {
		private var downloadTasks: [Int: DownloadTask] = [:]
		private var backgroundDownloadRegistry: [String: () -> Void] = [:]

		private var lock: NSLock = NSLock()

		fileprivate func addNewTask(task: DownloadTask) {
			lock.lock()

			defer { lock.unlock() }

			downloadTasks[task.id] = task
		}

		fileprivate func removeTask(task: DownloadTask) {
			lock.lock()

			defer { lock.unlock() }

			if downloadTasks[task.id] != nil {
				downloadTasks[task.id] = nil
			}
		}

		fileprivate func addBackgroundDownloadHandler(handler: @escaping () -> Void, identifier: String) {
			lock.lock()

			defer { lock.unlock() }

			backgroundDownloadRegistry[identifier] = handler
		}

		fileprivate func update(progress: Double, identifier: Int) {
			lock.lock()

			defer { lock.unlock() }

			if downloadTasks[identifier] != nil {
				downloadTasks[identifier]!.onProgress?(progress)
			}
		}

		fileprivate func finish(downloadingTo location: URL, identifier: Int) {
			lock.lock()

			defer { lock.unlock() }

			if downloadTasks[identifier] != nil {
				downloadTasks[identifier]!.onComplete?(.success(location))
				downloadTasks[identifier] = nil
			}
		}

		fileprivate func finish(withError error: Error, identifier: Int) {
			lock.lock()

			defer { lock.unlock() }

			if downloadTasks[identifier] != nil {
				downloadTasks[identifier]!.onComplete?(.failure(error))
				downloadTasks[identifier] = nil
			}
		}

		fileprivate func finishAllEvents(identifier: String) {
			lock.lock()

			defer { lock.unlock() }

			if backgroundDownloadRegistry[identifier] != nil {
				backgroundDownloadRegistry[identifier]?()
				backgroundDownloadRegistry[identifier] = nil
				downloadTasks.removeAll()
			}
		}

		fileprivate func updateTaskIdentifier(oldIdentifier: Int, newIdentifier: Int) {
			lock.lock()

			defer { lock.unlock() }

			if let task = downloadTasks[oldIdentifier] {
				downloadTasks.removeValue(forKey: oldIdentifier)
				downloadTasks[newIdentifier] = task
			}
		}

		fileprivate func getAllTasks() -> [REST.DownloadTask] {
			lock.lock()

			defer { lock.unlock() }

			return downloadTasks.values.map { $0 }
		}
	}
}
