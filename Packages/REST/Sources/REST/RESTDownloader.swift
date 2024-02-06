//
//  RESTDownloader.swift
//
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation
import Logger

public extension REST {
    class DownloadTask: Identifiable {
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
        fileprivate var _onComplete: ((Result<URL, Error>) -> Void)?
        fileprivate var _onProgress: ((Double) -> Void)?
        fileprivate var _onCancel: ((Bool) -> Void)?

        private var downloadTask: URLSessionDownloadTask
        private var resumedData: Data?

        public private(set) var state: State = .pending

        private let lock = NSLock()

        init(url: URL, downloadTask: URLSessionDownloadTask) {
            self.url = url
            self.downloadTask = downloadTask

            _onProgress = { [weak self] newProgress in
                self?.state = .inProgress
                self?.onProgress?(newProgress)
            }

            _onComplete = { [weak self] result in
                switch result {
                case .success:
                    self?.state = .completed
                case .failure:
                    self?.state = .failed
                }
                self?.onComplete?(result)
            }
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

            state = .pending
            downloadTask = onResumeCancelled(resumedData)
        }
    }

    class Downloader: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
        private let taskStore = DownloadTaskStore()
        private let operationsQueue = OperationQueue()

        private static var identifier: String = "io.lucaa.Loadle.Background"
        private static var dir = "DOWNLOADS"

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

        private lazy var urlSession: URLSession = {
            let config = URLSessionConfiguration.background(withIdentifier: Self.identifier)
            config.sessionSendsLaunchEvents = true
            return URLSession(configuration: config, delegate: self, delegateQueue: operationsQueue)
        }()

        public var allTasks: [DownloadTask] {
            return taskStore.getAllTasks()
        }

        public func startDownload(using url: URL) -> DownloadTask {
            let task = urlSession.downloadTask(with: url)
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

            return downloadTask
        }

        public func addBackgroundDownloadHandler(handler: @escaping () -> Void, identifier: String) {
            taskStore.addBackgroundDownloadHandler(handler: handler, identifier: identifier)
        }

        public func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            do {
                let newFileName = downloadTask.response?.suggestedFilename ?? location.lastPathComponent
                let savedURL = try Self.loadDownloadsURL().appending(component: newFileName, directoryHint: .notDirectory)
                try FileManager.default.moveItem(at: location, to: savedURL)
                taskStore.finish(downloadingTo: savedURL, identifier: downloadTask.taskIdentifier)
                log(.info, "Finished downloading! You can find your download in here: \(savedURL).")
            } catch {
                taskStore.finish(withError: error, identifier: downloadTask.taskIdentifier)
                log(.error, error)
            }
        }

        public func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            taskStore.update(progress: progress >= 0 ? progress : 0, identifier: downloadTask.taskIdentifier)
        }

        public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
            if let identifier = session.configuration.identifier, !identifier.isEmpty {
                taskStore.finishAllEvents(identifier: identifier)
            }
        }

        public func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            guard let error else { return }
            taskStore.finish(withError: error, identifier: task.taskIdentifier)
        }
    }

    fileprivate class DownloadTaskStore {
        private var downloadTasks: [Int: DownloadTask] = [:]
        private var backgroundDownloadRegistry: [String: () -> Void] = [:]

        private var lock: NSLock = .init()

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
                downloadTasks[identifier]!._onProgress?(progress)
            }
        }

        fileprivate func finish(downloadingTo location: URL, identifier: Int) {
            lock.lock()

            defer { lock.unlock() }

            if downloadTasks[identifier] != nil {
                downloadTasks[identifier]!._onComplete?(.success(location))
                downloadTasks[identifier] = nil
            }
        }

        fileprivate func finish(withError error: Error, identifier: Int) {
            lock.lock()

            defer { lock.unlock() }

            if downloadTasks[identifier] != nil {
                downloadTasks[identifier]!._onComplete?(.failure(error))
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
