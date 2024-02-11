//
//  HomeViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import Logger
import REST

enum HomeViewModelError: Error, CustomStringConvertible {
	case noValidURL(string: String)
	case noRedirectURL(inside: REST.HTTPResponse<POSTCobaltResponse>)

	var description: String {
		let description = "\(type(of: self))."
		switch self {
		case .noValidURL(let string):
			return description + "noValidURL: " + "Was not able to build a valid URL given: \(string)"
		case .noRedirectURL(let response):
			return description + "noRedirectURL: " + "There is no redirect URL inside: \(response)"
		}
	}
}

@MainActor
@Observable
final class HomeViewModel {
	public var loadingEvents: [LoadingEvent]
	public var isLoading: Bool = false
	public var audioOnly: Bool = false

	private var urlRegistry: [URL: URL] = [:]
	private let downloader = REST.Downloader.shared
	private let loader = REST.Loader.shared

	init() {
		do {
			let downloadURL = try REST.Downloader.loadDownloadsURL()
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

	func startDownload(using url: String, preferences: UserPreferences, onComplete: @escaping (Result<Void, Error>) -> Void) {
		guard !isLoading else { return }
		isLoading = true
		guard let url = URL(string: url) else {
			isLoading = false
			log(.error, HomeViewModelError.noValidURL(string: url))
			onComplete(.failure(HomeViewModelError.noValidURL(string: url)))
			return
		}
		load(using: url, preferences: preferences, audioOnly: audioOnly, onComplete: onComplete)
	}

	private func load(using url: URL, preferences: UserPreferences, audioOnly: Bool, onComplete: @escaping (Result<Void, Error>) -> Void) {
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
			self?.isLoading = false

			switch result {
			case .success(let response):
				guard let newURL = response.body.url else {
					onComplete(.failure(HomeViewModelError.noRedirectURL(inside: response)))
					return
				}
				self?.download(originalURL: url, redirectedURL: newURL)
				onComplete(.success(()))
			case .failure(let error):
				log(.error, error)
				onComplete(.failure(error))
			}
		}
	}

	private func download(originalURL: URL, redirectedURL: URL) {
		let event = LoadingEvent(url: originalURL)
		downloader.download(url: redirectedURL) { [weak self] newState in
			self?.process(newState, for: event)
		}

		urlRegistry[event.url] = redirectedURL
		loadingEvents.append(event)
	}

	private func process(_ state: REST.Download.State, for event: LoadingEvent) {
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

	public func delete(event: LoadingEvent) {
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
			downloader.deleteDownload(with: redirectURL)
		}
	}

	public func pauseDownload(event: LoadingEvent) {
		guard let redirectURL = urlRegistry[event.url] else { return }
		downloader.pauseDownload(with: redirectURL)
	}

	public func resumeDownload(event: LoadingEvent) {
		guard let redirectURL = urlRegistry[event.url] else { return }
		downloader.resumeDownload(with: redirectURL)
	}
}
