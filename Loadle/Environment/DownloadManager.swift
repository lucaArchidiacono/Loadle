//
//  DownloadManager.swift
//  Loadle
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation
import REST
import Logger

@MainActor
final class DownloadManager: Observable {
	@Published var downloads: [REST.DownloadTask] = []

	private static var host = "co.wuk.sh"

	private let downloader: REST.Downloader
	private let loader: REST.Loader

	init(downloader: REST.Downloader, loader: REST.Loader) {
		self.downloader = downloader
		self.loader = loader

		downloader.allTasks.forEach { downloadTask in
			downloads.append(downloadTask)
		}
	}

	func startDownload(using url: URL, preferences: UserPreferences) {
		load(using: url, userPreferences: preferences)
	}

	func load(using url: URL, userPreferences: UserPreferences) {
		let cobaltRequest = CobaltRequest(
			url: url,
			vCodec: userPreferences.videoYoutubeCodec,
			vQuality: userPreferences.videoDownloadQuality,
			aFormat: userPreferences.audioFormat,
			isAudioOnly: false,
			isNoTTWatermark: userPreferences.videoTiktokWatermarkDisabled,
			isTTFullAudio: userPreferences.audioTiktokFullAudio,
			isAudioMuted: userPreferences.audioMute,
			dubLang: userPreferences.audioYoutubeTrack == .original ? false : true,
			disableMetadata: false,
			twitterGif: userPreferences.videoTwitterConvertGifsToGif,
			vimeoDash: userPreferences.videoDownloadType == .progressive ? nil : true)
		let request = REST.HTTPRequest(host: Self.host, path: "/api/json", method: .post, body: REST.JSONBody(cobaltRequest))
		loader.load(using: request) { [weak self] (result: Result<REST.HTTPResponse<POSTCobaltResponse>, REST.HTTPError<POSTCobaltResponse>>) in
			guard let self else { return }
			switch result {
			case .success(let response):
				guard let url = response.body.url else { return }
				self.download(using: url)
			case .failure(let error):
				log(.error, error)
			}
		}
	}

	func download(using url: URL) {
		let downloadTask = downloader.startDownload(using: url)
		downloads.append(downloadTask)
	}
}
