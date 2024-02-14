//
//  DownloadService.swift
//  Loadle
//
//  Created by Luca Archidiacono on 14.02.2024.
//

import Foundation
import Logger
import REST
import Constants
import SwiftUI
import Models

@Observable
@MainActor
public final class DownloadService {
	public enum ServiceError: Error, CustomStringConvertible {
		case noValidURL(string: String)
		case noRedirectURL(inside: REST.HTTPResponse<POSTCobaltResponse>)

		public var description: String {
			let description = "\(type(of: self))."
			switch self {
			case .noValidURL(let string):
				return description + "noValidURL: " + "Was not able to build a valid URL given: \(string)"
			case .noRedirectURL(let response):
				return description + "noRedirectURL: " + "There is no redirect URL inside: \(response)"
			}
		}
	}

	public var downloads: [DownloadItem] = []
	public var debuggingBackgroundTasks: Bool {
		#if DEBUG
		return true
		#else
		return false
		#endif
	}

	@ObservationIgnored
	private var urlRegistry: [URL: URL] = [:]
	@ObservationIgnored
	private var backgroundCompletionHandlers: [() -> Void] = []
	@ObservationIgnored
	private let loader = REST.Loader.shared
	@ObservationIgnored
	private lazy var downloader: REST.Downloader = {
		return REST.Downloader.shared(withDebuggingBackgroundTasks: debuggingBackgroundTasks)
	}()

	public static let shared = DownloadService()

	private init() {
		downloader.backgroundCompletionHandler = { [weak self] in
			self?.backgroundCompletionHandlers.forEach { $0() }
			self?.backgroundCompletionHandlers = []
		}
	}

	public func downloadWebsite(ursing url: String, preferences: UserPreferences, onComplete: @escaping (Result<Void, Error>) -> Void) {
		guard let url = URL(string: url) else {
			onComplete(.failure(ServiceError.noValidURL(string: url)))
			return
		}

		// Download Website as archive
	}

	public func downloadMedia(using url: String, preferences: UserPreferences, audioOnly: Bool, onComplete: @escaping (Result<Void, Error>) -> Void) {
		guard let url = URL(string: url) else {
			onComplete(.failure(ServiceError.noValidURL(string: url)))
			return
		}

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
				self?.download(originalURL: url, redirectedURL: response.body.url!)
				onComplete(.success(()))
			case .failure(let error):
				log(.error, error)
				onComplete(.failure(error))
			}
		}
	}

	private func download(originalURL: URL, redirectedURL: URL) {
		let download = DownloadItem(remoteURL: originalURL)
		urlRegistry[originalURL] = redirectedURL
		downloads.append(download)

		downloader.download(url: redirectedURL) { [weak self] newState in
			self?.process(newState, for: download)
		}
	}

	private func process(_ state: REST.Downloader.ResultState, for download: DownloadItem) {
		guard let downloadIndex = downloads.firstIndex(where: { $0.id == download.id }) else { return }
		var registeredDownload = downloads[downloadIndex]
		switch state {
		case .progress(let currentBytes, let totalBytes):
			registeredDownload.update(state: .progress(currentBytes: currentBytes, totalBytes: totalBytes))
			downloads[downloadIndex] = registeredDownload
		case .success(let url):
			log(.info, "Successfully downloaded and stored the media at: \(url)")
			downloads.remove(at: downloadIndex)
		case .failed(let error):
			log(.error, "The download failed due to the following error: \(error)")
			registeredDownload.update(state: .failed)
			downloads[downloadIndex] = registeredDownload
		case .cancelled:
			registeredDownload.update(state: .cancelled)
			downloads[downloadIndex] = registeredDownload
		}
	}

	public func delete(download: DownloadItem) {
		guard let downloadIndex = downloads.firstIndex(where: { $0.id == download.id }) else { return }
		let registeredDownload = downloads[downloadIndex]
		if let redirectURL = urlRegistry[registeredDownload.remoteURL] {
			downloader.deleteDownload(with: redirectURL)
		}
		downloads.remove(at: downloadIndex)
	}

	public func cancel(download: DownloadItem) {
		guard let redirectURL = urlRegistry[download.remoteURL] else { return }
		downloader.cancelDownload(with: redirectURL)
	}

	public func resume(download: DownloadItem) {
		guard let redirectURL = urlRegistry[download.remoteURL] else { return }
		downloader.resumeDownload(with: redirectURL)
	}

	public func addBackgroundCompletionHandler(handler: @escaping () -> Void) {
		backgroundCompletionHandlers.append(handler)
	}
}
