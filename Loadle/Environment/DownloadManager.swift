//
//  DownloadManager.swift
//  Loadle
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation
import Logger
import REST

@MainActor
@Observable
final class DownloadManager {
    var downloads: [REST.DownloadTask] = []

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
        load(using: url, preferences: preferences)
    }

    private func load(using url: URL, preferences: UserPreferences) {
        let cobaltRequest = CobaltRequest(
            url: url,
            vCodec: preferences.videoYoutubeCodec,
            vQuality: preferences.videoDownloadQuality,
            aFormat: preferences.audioFormat,
            isAudioOnly: false,
            isNoTTWatermark: preferences.videoTiktokWatermarkDisabled,
            isTTFullAudio: preferences.audioTiktokFullAudio,
            isAudioMuted: preferences.audioMute,
            dubLang: preferences.audioYoutubeTrack == .original ? false : true,
            disableMetadata: false,
            twitterGif: preferences.videoTwitterConvertGifsToGif,
            vimeoDash: preferences.videoVimeoDownloadType == .progressive ? nil : true
        )
        let request = REST.HTTPRequest(host: Self.host, path: "/api/json", method: .post, body: REST.JSONBody(cobaltRequest))
        loader.load(using: request) { [weak self] (result: Result<REST.HTTPResponse<POSTCobaltResponse>, REST.HTTPError<POSTCobaltResponse>>) in
            guard let self else { return }
            switch result {
            case let .success(response):
                guard let url = response.body.url else { return }
                self.download(using: url, request: cobaltRequest, filenameStyle: preferences.filenameStyle)
            case let .failure(error):
                log(.error, error)
            }
        }
    }

    private func download(using url: URL, request _: CobaltRequest, filenameStyle _: FilenameStyle) {
        let downloadTask = downloader.startDownload(using: url)
        downloadTask.onComplete = { result in
            switch result {
            case let .success(location):
				if let index = self.downloads.firstIndex(where: { $0.id == downloadTask.id }) {
					self.downloads.remove(at: index)
				}
            case let .failure(error):
                log(.error, error)
            }
        }
        downloads.append(downloadTask)
    }
}
