//
//  DownloadManager.swift
//  Loadle
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation
import Logger
import REST
import SwiftUI

@MainActor
@Observable
final class DownloadManager: NSObject, URLSessionDelegate {
	private static var identifier: String = "io.lucaa.Loadle.DownloadManager"
	private static var dir = "DOWNLOADS"

	public var urlRegistry: [URL: URL] = [:]
	public var loadingEvents: [LoadingEvent]
	public var previews: [LoadingEvent] = [
		LoadingEvent(url: URL(string: "http://google.ch")!),
	]
	private var downloads: [URL: Download] = [:]

	private var backgroundDownloadRegistry: [String: () -> Void] = [:]

	private let loader: REST.Loader

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

	@ObservationIgnored
	private lazy var downloadSession: URLSession = {
		let config = URLSessionConfiguration.background(withIdentifier: Self.identifier)
		config.sessionSendsLaunchEvents = true
		config.allowsCellularAccess = true
		return URLSession(configuration: config, delegate: self, delegateQueue: .main)
	}()

	public static var shared = DownloadManager()

    private override init() {
		self.loader = REST.Loader()

		do {
			let downloadURL = try Self.loadDownloadsURL()
			let contents = try FileManager.default
				.contentsOfDirectory(at: downloadURL, includingPropertiesForKeys: [.addedToDirectoryDateKey, .isHiddenKey], options: .skipsHiddenFiles)
			self.loadingEvents = contents
				.compactMap { url in
					var event = LoadingEvent(url: url)
					event.update(state: .success(url: url))
					return event
				}
		} catch {
			log(.error, error)
			self.loadingEvents = []
		}
    }

	func startDownload(using url: String, preferences: UserPreferences, audioOnly: Bool) {
		guard let url = URL(string: url) else {
			log(.error, "No valid URL!")
			return
		}
		load(using: url, preferences: preferences, audioOnly: audioOnly)
    }

	private func load(using url: URL, preferences: UserPreferences, audioOnly: Bool) {
        let cobaltRequest = CobaltRequest(
            url: url,
            vCodec: preferences.videoYoutubeCodec,
            vQuality: preferences.videoDownloadQuality,
            aFormat: preferences.audioFormat,
            isAudioOnly: audioOnly,
            isNoTTWatermark: preferences.videoTiktokWatermarkDisabled,
            isTTFullAudio: preferences.audioTiktokFullAudio,
            isAudioMuted: preferences.audioMute,
            dubLang: preferences.audioYoutubeTrack == .original ? false : true,
            disableMetadata: false,
            twitterGif: preferences.videoTwitterConvertGifsToGif,
            vimeoDash: preferences.videoVimeoDownloadType == .progressive ? nil : true
        )
        let request = REST.HTTPRequest(host: "co.wuk.sh", path: "/api/json", method: .post, body: REST.JSONBody(cobaltRequest))
		loader.load(using: request) { [weak self] (result: Result<REST.HTTPResponse<POSTCobaltResponse>, REST.HTTPError<POSTCobaltResponse>>) in
			switch result {
			case .success(let response):
				guard let newURL = response.body.url else { return }
				self?.download(originalURL: url, redirectedURL: newURL)
			case .failure(let error):
				log(.error, error)
			}
		}
    }

	private func download(originalURL: URL, redirectedURL: URL) {
		let event = LoadingEvent(url: originalURL)
		let task = downloadSession.downloadTask(with: redirectedURL)
		let download = Download(task: task) { [weak self] newState in
			self?.process(newState, for: event)
		}
		
		urlRegistry[event.url] = redirectedURL
		downloads[redirectedURL] = download
		loadingEvents.append(event)

		download.start()
    }

	private func process(_ state: Download.State, for event: LoadingEvent) {
		guard let eventIndex = loadingEvents.firstIndex(where: { $0.id == event.id }) else { return }
		var registeredEvent = loadingEvents[eventIndex]
		registeredEvent.update(state: state)
		loadingEvents[eventIndex] = registeredEvent

		if case let .success(url) = state {
			log(.info, "Successfully downloaded and stored the media at: \(url)")
		} else if case .failed(let error) = state {
			log(.error, "The download failed due to the following error: \(error)")
		}
	}

	public func delete(for event: LoadingEvent) {
		guard let eventIndex = loadingEvents.firstIndex(where: { $0.id == event.id }) else { return }
		let event = loadingEvents[eventIndex]

		if let fileURL = event.fileURL {
			do {
				try FileManager.default.removeItem(at: fileURL)
			} catch {
				log(.error, error)
			}
		}
		loadingEvents.remove(at: eventIndex)
		if let redirectURL = urlRegistry[event.url] {
			downloads.removeValue(forKey: redirectURL)
		}
	}

	public func pauseDownload(for event: LoadingEvent) {
		guard let redirectURL = urlRegistry[event.url] else { return }
		downloads[redirectURL]?.pause()
	}

	public func resumeDownload(for event: LoadingEvent) {
		guard let redirectURL = urlRegistry[event.url] else { return }
		downloads[redirectURL]?.resume()
	}

	public func addBackgroundDownloadHandler(handler: @escaping () -> Void, identifier: String) {
		backgroundDownloadRegistry[identifier] = handler
	}
}

extension DownloadManager: URLSessionDownloadDelegate {
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		guard let url = downloadTask.originalRequest?.url else { return }
		downloads[url]?.onStateChange(
			.progress(
				currentBytes: Double(totalBytesWritten),
				totalBytes: Double(totalBytesExpectedToWrite)))
	}

	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		guard let url = downloadTask.originalRequest?.url else { return }
		let newFilename = downloadTask.response?.suggestedFilename ?? UUID().uuidString
		do {
			let downloadURL = try Self.loadDownloadsURL()
				.appendingPathComponent(newFilename, conformingTo: .fileURL)
			try FileManager.default.moveItem(at: location, to: downloadURL)
			downloads[url]?.onStateChange(.success(url: downloadURL))
			downloads[url] = nil
		} catch {
			downloads[url]?.onStateChange(.failed(error: error))
		}
	}

	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard let error, let url = task.originalRequest?.url else { return }
		downloads[url]?.onStateChange(.failed(error: error))
		downloads[url]?.finish()
	}
}

class Download: NSObject {
	enum State {
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
	fileprivate let onStateChange: (State) -> Void

	fileprivate init(task: URLSessionDownloadTask, onStateChange: @escaping (State) -> Void) {
		self.task = task
		self.onStateChange = onStateChange
	}

	deinit { finish() }

	fileprivate var isDownloading: Bool {
		task.state == .running
	}

	fileprivate func update(state: State) {
		currentState = state
	}

	fileprivate func start() {
		task.resume()
	}

	fileprivate func pause() {
		onStateChange(.paused)
		task.suspend()
	}

	fileprivate func resume() {
		task.resume()
	}

	fileprivate func finish() {
		task.cancel()
	}
}
