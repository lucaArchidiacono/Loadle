//
//  RESTDownloader.swift
//
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import Logger

extension REST {
    public class Downloader: NSObject, URLSessionDownloadDelegate {
		static func loadBaseURL() throws -> URL {
			let downloadURL = try FileManager.default.url(for: .documentDirectory,
														  in: .userDomainMask,
														  appropriateFor: .documentsDirectory,
														  create: true)
				.appending(component: "DOWNLOADS", directoryHint: .isDirectory)

			if !FileManager.default.fileExists(atPath: downloadURL.standardizedFileURL.path(percentEncoded: false)) {
				try FileManager.default.createDirectory(at: downloadURL, withIntermediateDirectories: true)
			}

			return downloadURL
		}

        fileprivate class DownloaderStore {
            private let queue = DispatchQueue(label: "REST.Downloader.Store")
            private var downloads: [URL: Download] = [:]

			fileprivate func setup(using session: URLSession) {
				log(.verbose, "Will fetch all tasks.")
				queue.async { [weak self] in
					guard let self else { return }

					log(.verbose, "Is fetching tasks.")
					let group = DispatchGroup()
					
					group.enter()
					session.getAllTasks { tasks in
						defer { group.leave() }

						let runningDownloads = tasks
							.compactMap { task -> (URL, Download)? in
								guard let downloadTask = task as? URLSessionDownloadTask, let url = downloadTask.originalRequest?.url else { return nil }
								let download = Download(downloadTask: downloadTask, session: session, url: url)
								return (url, download)
							}
							.reduce(into: [URL: Download](), { partialResult, couple in
								partialResult[couple.0] = couple.1
							})

						log(.verbose, "Found following running tasks: \(runningDownloads)")
						self.downloads = runningDownloads
					}

					log(.verbose, "Waiting for task fetching to be done.")
					group.wait()
					log(.verbose, "Finished fetching tasks")
				}
			}

			fileprivate func getAllDownloads(onComplete: @escaping ([Download]) -> Void) {
				log(.verbose, "Will fetch all stored downloads.")
				queue.async { [weak self] in
					guard let self else { return }
					log(.verbose, "Is fetching stored downloads.")
					let downloads = Array(self.downloads.values).sorted(by: { $0.createdAt < $1.createdAt })
					log(.verbose, "downloads: \(downloads)")
					onComplete(downloads)
					log(.verbose, "Finished fetching stored downloads.")
				}
			}

            fileprivate func add(new download: Download, using url: URL) {
				log(.verbose, "Will add download to store.")
                queue.sync { [weak self] in
					guard let self else { return }
					log(.verbose, "Is adding download to store.")
					log(.verbose, "download: \(download), url: \(url)")
                    downloads[url] = download
					log(.verbose, "Finished adding download to store.")
                }
            }

            fileprivate func cancel(using url: URL) {
				log(.verbose, "Will cancel download to store.")
                queue.sync { [weak self] in
					guard let self else { return }
					log(.verbose, "Is cancelling download to store.")
					if let download = downloads[url] {
						log(.verbose, "download: \(download), url: \(url)")
						download.pause()
					} else {
						log(.warning, "Was not able to find download using url: \(url)")
					}
					log(.verbose, "url: \(url)")
					log(.verbose, "Finished cancelling download to store.")
                }
            }

            fileprivate func delete(using url: URL) {
				log(.verbose, "Will delete download to store.")
                queue.sync { [weak self] in
					guard let self else { return }
					log(.verbose, "Is deleting download to store.")
					if let download = downloads[url] {
						log(.verbose, "download: \(download), url: \(url)")
						download.cancel()
						downloads.removeValue(forKey: url)
					} else {
						log(.warning, "Was not able to find download using url: \(url)")
					}
					log(.verbose, "Finished deleting download to store.")
                }
            }

            fileprivate func resume(using url: URL) {
				log(.verbose, "Will resume download to store.")
                queue.sync { [weak self] in
					guard let self else { return }
					log(.verbose, "Is resuming download to store.")
					if let download = downloads[url] {
						log(.verbose, "download: \(download), url: \(url)")
						download.resume()
					} else {
						log(.warning, "Was not able to find download using url: \(url)")
					}
					log(.verbose, "Finished resuming download to store.")
                }
            }

            fileprivate func updateProgress(using url: URL, currentBytes: Int64, totalBytes: Int64) {
				log(.verbose, "Will update download with progress state.")
                queue.async { [weak self] in
					guard let self else { return }
					log(.verbose, "Is updating download with progress state.")
					if let download = downloads[url] {
						log(.verbose, "download: \(download), url: \(url), currentBytes: \(currentBytes), totalBytes: \(totalBytes)")
						download.updateProgress(currentBytes: currentBytes, totalBytes: totalBytes)
					} else {
						log(.warning, "Was not able to find download using url: \(url)")
					}
					log(.verbose, "Finished download task with progress state.")
                }
            }

            fileprivate func complete(using url: URL, newFileLocation: URL) {
				log(.verbose, "Will complete download task with success.")
                queue.async { [weak self] in
					guard let self else { return }

					log(.verbose, "Is completing download task with success.")
					if let download = downloads[url] {
						log(.verbose, "download: \(download), remoteURL: \(url), fileURL: \(newFileLocation)")
						download.complete(with: newFileLocation)
					} else {
						log(.warning, "Was not able to find download using url: \(url)")
					}
                    downloads[url] = nil
					log(.verbose, "Finished completing download task with success.")
                }
            }

            fileprivate func complete(using url: URL, error: Error) {
				log(.verbose, "Will complete download task with error.")
                queue.async { [weak self] in
					guard let self else { return }

					log(.verbose, "Is completing download task with error.")
					if let download = downloads[url] {
						log(.verbose, "download: \(download), error: \(error)")
						download.complete(with: error)
					} else {
						log(.warning, "Was not able to find download using url: \(url)")
					}
					log(.verbose, "Finished completing download task with error.")
                }
            }
        }

        public enum ResultState {
			case pending
            case cancelled
            case progress(currentBytes: Double, totalBytes: Double)
            case success(url: URL)
            case failed(error: Error)
        }

        private static var identifier: String = "io.lucaa.Loadle.DownloadManager"

        public var backgroundCompletionHandler: (() -> Void)?

        private let debuggingBackroundTasks: Bool
		private let store: DownloaderStore

        private lazy var downloadSession: URLSession = {
            let config = URLSessionConfiguration.background(withIdentifier: Self.identifier)
            config.sessionSendsLaunchEvents = true
            config.allowsCellularAccess = true
            return URLSession(configuration: config, delegate: self, delegateQueue: .main)
        }()

        public static func shared(withDebuggingBackgroundTasks: Bool = false) -> REST.Downloader {
            return REST.Downloader(debuggingBackroundTasks: withDebuggingBackgroundTasks)
        }

        private init(debuggingBackroundTasks: Bool) {
            self.debuggingBackroundTasks = debuggingBackroundTasks
			self.store = DownloaderStore()

            super.init()

            if debuggingBackroundTasks {
                URLSession.shared.invalidateAndCancel()
            }

			store.setup(using: downloadSession)
        }

		public func getAllDownloads(onComplete: @escaping ([Download]) -> Void) {
			store.getAllDownloads(onComplete: onComplete)
		}

        public func download(url: URL, onStateChange: @escaping (ResultState) -> Void) {
            let download = Download(session: downloadSession, url: url)
			download.completionHandler = onStateChange
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

        public func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            guard let url = downloadTask.originalRequest?.url else { return }
            store.updateProgress(using: url, currentBytes: totalBytesWritten, totalBytes: totalBytesExpectedToWrite)
        }

        public func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            guard let url = downloadTask.originalRequest?.url else { return }
            let newFilename = downloadTask.response?.suggestedFilename ?? UUID().uuidString
            do {
				let downloadURL = try Self.loadBaseURL()
					.appending(component: newFilename, directoryHint: .notDirectory)
				if FileManager.default.fileExists(atPath: downloadURL.standardizedFileURL.path(percentEncoded: false)) {
					try FileManager.default.removeItem(at: downloadURL)
				}
				try FileManager.default.moveItem(at: location, to: downloadURL)
                store.complete(using: url, newFileLocation: downloadURL)
            } catch {
                store.complete(using: url, error: error)
            }
        }

        public func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            guard let error, let url = task.originalRequest?.url else { return }
			if let urlError = error as NSError?, urlError.code == NSURLErrorCancelled { return }
            store.complete(using: url, error: error)
        }

        public func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
            guard let url = downloadTask.originalRequest?.url else { return }
            store.updateProgress(using: url, currentBytes: fileOffset, totalBytes: expectedTotalBytes)
        }

        public func urlSessionDidFinishEvents(forBackgroundURLSession _: URLSession) {
            DispatchQueue.main.async {
                self.backgroundCompletionHandler?()
                self.backgroundCompletionHandler = nil
            }
        }
    }

    public class Download: NSObject {
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

		fileprivate let createdAt: Date = .now

        public let url: URL
		public var completionHandler: ((Downloader.ResultState) -> Void)? {
			didSet {
				completionHandler?(resultState)
			}
		}

		private(set) fileprivate var resultState: Downloader.ResultState = .pending {
			didSet {
				completionHandler?(resultState)
			}
		}
        private(set) fileprivate var state: State = .ready

        var isCoalescable: Bool {
            return (state == .ready) ||
                (state == .downloading) ||
                (state == .paused)
        }

        var isResumable: Bool {
            return (state == .ready) ||
                (state == .paused)
        }

        var isPaused: Bool {
            return state == .paused
        }

        var isCompleted: Bool {
            return state == .completed
        }

		init(downloadTask: URLSessionDownloadTask? = nil, session: URLSession, url: URL) {
			self.downloadTask = downloadTask
            self.session = session
            self.url = url
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
					self.resultState = .cancelled
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

            resultState = .success(url: newFileLocation)
        }

        fileprivate func complete(with error: Error) {
            defer {
                if state != .paused {
                    state = .completed
                }

                cleanup()
            }

			resultState = .failed(error: error)
        }

        fileprivate func updateProgress(currentBytes: Int64, totalBytes: Int64) {
            completionHandler?(.progress(currentBytes: Double(currentBytes), totalBytes: Double(totalBytes)))
        }

        private func cleanup() {
            downloadTask = nil
        }
    }
}
