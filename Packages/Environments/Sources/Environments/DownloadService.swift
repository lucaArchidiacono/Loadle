//
//  DownloadService.swift
//  Loadle
//
//  Created by Luca Archidiacono on 14.02.2024.
//

import Combine
import Constants
import Foundation
import Generator
import LinkPresentation
import LocalStorage
import Logger
import Models

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
    private var store: [URL: WrappedDownload] = [:]

    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }

    public func add(using remoteURL: URL, streamURL: URL, mediaService: MediaService, metadata: LPLinkMetadata) async {
        log(.info, "🏁 Start adding new Download using: remoteURL -> \(remoteURL); streamURL -> \(streamURL); mediaService -> \(mediaService); metadata -> \(metadata)")
        let downloadItem = DownloadItem(remoteURL: remoteURL, streamURL: streamURL, service: mediaService, metadata: metadata)
        let downloadTask = DownloadTask(session: urlSession, url: streamURL)
        let wrappedDownload = WrappedDownload(item: downloadItem, task: downloadTask)

        do {
            try await Storage.DownloadItem.write(downloadItem)

            store[wrappedDownload.item.streamURL] = WrappedDownload(item: downloadItem, task: downloadTask)

            downloadTask.resume()
            log(.info, "✅ Finished adding new Download.")
        } catch {
            log(.error, error)
        }
    }

    public func delete(using url: URL) async {
        log(.info, "🏁 Is deleting Download using url: \(url)")
        guard let wrappedDownload = store[url] else {
            log(.warning, "Was not able to find and delete Download with url: \(url)")
            return
        }
        do {
            try await Storage.DownloadItem.delete(wrappedDownload.item.id)

            wrappedDownload.task.cancel()
            store.removeValue(forKey: url)

            log(.info, "✅ Finished deleting Download.")
        } catch {
            log(.error, "Failed to delete Download successfully.")
        }
    }

    public func cancel(using url: URL) async {
        log(.info, "🏁 Is cancelling Download using url: \(url)")
        guard let wrappedDownload = store[url] else {
            log(.warning, "Was not able to find and cancel Download with url: \(url)")
            return
        }

        guard !wrappedDownload.task.isPaused else { return }

        await wrappedDownload.task.pause()
        log(.info, "✅ Finished canelling Download.")
    }

    public func resume(using url: URL) async {
        log(.info, "🏁 Is resuming Download using url: \(url)")
        guard let wrappedDownload = store[url] else {
            log(.warning, "Was not able to find and resume Download with url: \(url)")
            return
        }

        guard wrappedDownload.task.isResumable else { return }

        wrappedDownload.task.resume()
        log(.info, "✅ Finished resuming Download.")
    }

    public func update(using task: URLSessionDownloadTask, newState: URLSessionDownloadDelegateWrapper.State) async -> [DownloadItem] {
        log(.info, "🏁 Is updating Download using task: \(task)")
        guard let url = task.originalRequest?.url else { return [] }

        log(.verbose, "New state \(newState) received for url: \(url)")

        guard let downloadItem = await Storage.DownloadItem.search(url) else {
            log(.warning, "Was not able to find and update `DownloadItem` with url: \(url)")
            return []
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

            do {
                try await Storage.DownloadItem.write(updatedDownloadItem)
                store[url] = WrappedDownload(item: updatedDownloadItem, task: currentWrappedDownload.task)
            } catch {
                log(.error, error)
            }
        case let .success(fileURL):
            log(.info, "Successfully downloaded the media: \(fileURL)")

            do {
                try await Storage.DownloadItem.delete(url)
                store.removeValue(forKey: url)
                await MediaAssetService.shared.store(downloadItem: downloadItem, originalFileURL: fileURL)
            } catch {
                log(.error, error)
            }
        case let .failed(error):
            log(.error, "The Download failed due to the following error: \(error)")
            let updatedDownloadItem = downloadItem.update(state: .failed)

            do {
                try await Storage.DownloadItem.write(downloadItem)
                store[url] = WrappedDownload(item: updatedDownloadItem, task: currentWrappedDownload.task)
            } catch {
                log(.error, error)
            }
        case .cancelled:
            log(.warning, "Download has been cancelled with following url: \(url)")
            let updatedDownloadItem = downloadItem.update(state: .cancelled)

            do {
                try await Storage.DownloadItem.write(downloadItem)
                store[url] = WrappedDownload(item: updatedDownloadItem, task: currentWrappedDownload.task)
            } catch {
                log(.error, error)
            }
        }
        log(.info, "✅ Finished updating Download.")
        return store.values.map { $0.item }
    }
}

public class DownloadService: NSObject {
    private let delegate: URLSessionDownloadDelegateWrapper = .init()
    private let store: DownloadStore
    private let downloadSession: URLSession

    private var backgroundCompletionHandlers: [() -> Void] = []

    private var downloadContinuations: [UUID: AsyncStream<[DownloadItem]>.Continuation] = [:]

    private var stateTask: Task<Void, Never>?
    private var stateContinuation: AsyncStream<(URLSessionDownloadTask, URLSessionDownloadDelegateWrapper.State)>.Continuation?
    private lazy var states: AsyncStream<(URLSessionDownloadTask, URLSessionDownloadDelegateWrapper.State)> = AsyncStream { (continuation: AsyncStream<(URLSessionDownloadTask, URLSessionDownloadDelegateWrapper.State)>.Continuation) in
        continuation.onTermination = { @Sendable _ in
            self.stateContinuation = nil
        }
        self.delegate.onUpdate = { task, newState in
            continuation.yield((task, newState))
        }
        self.stateContinuation = continuation
    }

    public static let shared = DownloadService()

    override public init() {
        let config = URLSessionConfiguration.background(withIdentifier: Constants.Downloads.identifier)
        config.sessionSendsLaunchEvents = true
        config.allowsCellularAccess = true
        downloadSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        store = DownloadStore(urlSession: downloadSession)

        super.init()

        stateTask = Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            for await (task, newState) in self.states {
                let downloadItems = await self.store.update(using: task, newState: newState)
                downloadsSubject.send(downloadItems)
                downloadContinuations.values.forEach { $0.yield(downloadItems) }
            }
        }

        delegate.onComplete = { [weak self] in
            self?.backgroundCompletionHandlers.forEach { $0() }
            self?.backgroundCompletionHandlers = []
        }
    }

    deinit {
        stateTask?.cancel()
    }

    public func download(using remoteURL: URL, streamURL: URL, mediaService: MediaService, metadata: LPLinkMetadata) async {
        await store.add(using: remoteURL, streamURL: streamURL, mediaService: mediaService, metadata: metadata)
    }

    /// Sends a stream of updates based on current downloads using `Combine`'s `PassthroughSubject`.
    public var downloadsSubject: PassthroughSubject<[DownloadItem], Never> = PassthroughSubject()
    /// Sends a stream of updates based on current downloads using `AsyncStream`.
    /// Please keep in mind. When using this, also manually cancel your task.
    /// Since this is a never ending stream, you need to manually cancel the Task which is consuming this AsyncStream.
    public var downloadsStream: AsyncStream<[DownloadItem]> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            continuation.onTermination = { @Sendable _ in
                self.downloadContinuations.removeValue(forKey: id)
            }
            self.downloadContinuations[id] = continuation
        }
    }

    private var _deleteTasks: [URL: Task<Void, Never>] = [:]
    public func delete(using url: URL) {
        guard _deleteTasks[url] == nil else { return }

        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            self._deleteTasks[url] = Task {
                await self.store.delete(using: url)
            }

            await self._deleteTasks[url]?.value
            self._deleteTasks[url] = nil
        }
    }

    private var _cancelTasks: [URL: Task<Void, Never>] = [:]
    public func cancel(using url: URL) {
        guard _cancelTasks[url] == nil else { return }

        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            self._cancelTasks[url] = Task {
                await self.store.cancel(using: url)
            }
            await self._cancelTasks[url]?.value
            self._cancelTasks[url] = nil
        }
    }

    private var _resumeTasks: [URL: Task<Void, Never>] = [:]
    public func resume(using url: URL) {
        guard _resumeTasks[url] == nil else { return }

        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            self._resumeTasks[url] = Task {
                await self.store.resume(using: url)
            }
            await self._resumeTasks[url]?.value
            self._resumeTasks[url] = nil
        }
    }

    public func addBackgroundCompletionHandler(completion: @escaping () -> Void) {
        backgroundCompletionHandlers.append(completion)
    }
}

import SwiftUI

public extension View {
    @MainActor
    func onCompletedDownload(_ onCompletion: @escaping () -> Void) -> some View {
        modifier(DownloadServiceViewModifier(onCompletion: onCompletion))
    }
}

@MainActor
struct DownloadServiceViewModifier: ViewModifier {
    @State private var currentDownloadCount: Int = 0

    private let onCompletion: () -> Void

    init(onCompletion: @escaping () -> Void) {
        self.onCompletion = onCompletion
    }

    func body(content: Content) -> some View {
        content
            .task {
                for await downloadItems in DownloadService.shared.downloadsStream {
                    if currentDownloadCount > 0 && downloadItems.count == 0 {
                        onCompletion()
                    } else {
                        currentDownloadCount = downloadItems.count
                    }
                }
            }
    }
}
