//
//  DownloadViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import Logger
import SwiftUI
import REST

enum DownloadViewModelError: Error, CustomStringConvertible {
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
final class DownloadViewModel {
	public var downloads: [DownloadItem]
	public var loadedAssets: [AssetItem]
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
			self.loadedAssets = contents
				.compactMap { AssetItem(fileURL: $0) }
		} catch {
			log(.error, error)
			self.loadedAssets = []
		}

		self.downloads = []
	}

	func startDownload(using url: String, preferences: UserPreferences, onComplete: @escaping (Result<Void, Error>) -> Void) {
		guard !isLoading else { return }
		isLoading = true
		guard let url = URL(string: url) else {
			isLoading = false
			log(.error, DownloadViewModelError.noValidURL(string: url))
			onComplete(.failure(DownloadViewModelError.noValidURL(string: url)))
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
					onComplete(.failure(DownloadViewModelError.noRedirectURL(inside: response)))
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
			let assetItem = AssetItem(fileURL: url)
			downloads.remove(at: downloadIndex)
			loadedAssets.append(assetItem)
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

	public func delete(asset: AssetItem) {
		guard let loadedAssetIndex = loadedAssets.firstIndex(where: { $0.id == asset.id }) else { return }
		do {
			try FileManager.default.removeItem(at: asset.fileURL)
		} catch {
			log(.error, error)
		}
		loadedAssets.remove(at: loadedAssetIndex)
	}

	public func cancel(download: DownloadItem) {
		guard let redirectURL = urlRegistry[download.remoteURL] else { return }
		downloader.cancelDownload(with: redirectURL)
	}

	public func resume(download: DownloadItem) {
		guard let redirectURL = urlRegistry[download.remoteURL] else { return }
		downloader.resumeDownload(with: redirectURL)
	}
}
