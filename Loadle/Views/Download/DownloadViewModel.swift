//
//  DownloadViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Combine
import Environments
import Foundation
import Generator
import Logger
import Models
import REST
import SwiftUI

@MainActor
@Observable
final class DownloadViewModel {
    public var errorDetails: ErrorDetails?
    public var audioOnly: Bool = false
    public var downloadItems: [DownloadItem] = []
    public var isLoading: Bool = false
    public var url: String = ""

    @ObservationIgnored
    private var observationTask: Task<Void, Never>?
    @ObservationIgnored
    private var downloadTasks: [Task<Void, Never>] = []
    @ObservationIgnored
    private var subscriptions: Set<AnyCancellable> = Set()

    init() {
        observationTask = Task { [weak self] in
            for await downloadItems in DownloadService.shared.downloadsStream {
                self?.downloadItems = downloadItems
            }
        }
        //		DownloadService.shared.downloads
        //			.receive(on: RunLoop.main)
        //			.sink { [weak self] downloads in
        //				self?.downloadItems = downloads
        //			}
        //			.store(in: &subscriptions)
    }

    deinit {
        observationTask?.cancel()
        downloadTasks.forEach { $0.cancel() }
    }

    func startDownload(using url: String) {
        guard !isLoading else { return }

        log(.info, "🏁 Start downloading using url: \(url)")

        guard let url = URL(string: url), UIApplication.shared.canOpenURL(url) else {
            log(.error, "Can not open the provided url!")
            errorDetails = ErrorDetails(
                title: L10n.invalidUrlTitle,
                description: L10n.invalidUrlWrongDescription,
                actions: [.primary(title: L10n.ok)]
            )
            return
        }

        let downloadTask = Task { [weak self] in
            guard let self else { return }

            guard let mediaService = MediaService.allServices.first(where: { url.matchesRegex(pattern: $0.regex) }) else {
                log(.error, "Is an invalid URL which is not supported by the App!")
                errorDetails = ErrorDetails(
                    title: L10n.invalidUrlTitle,
                    description: L10n.invalidUrlWrongServiceDescription,
                    actions: [.primary(title: L10n.ok)]
                )
                return
            }

            do {
                self.isLoading = true

                let metadata = try await MetadataService.shared.fetch(using: url)

                guard let url = metadata.url else {
                    log(.error, "Was not able to fetch url from metadata!")
                    errorDetails = ErrorDetails(
                        title: L10n.notReachableUrlTitle,
                        description: L10n.notReachableUrlDescription,
                        actions: [.primary(title: L10n.ok)]
                    )
                    return
                }

                /// We need to first fetch the new url from the metada.
                /// Reason for it has to do with the fact that URL's coming from iMessage or copying using third party apps (such as the in house Reddit App), provides an URL which is not recognised by the Cobalt API.
                /// While using the URL and passing it to the MetaDataService, we should get the original URL (one which is visible by using the normal desktop browser).
                let cobaltRequest = DataTransformer.Request.transform(
                    url: url,
                    mediaService: mediaService,
                    videoYoutubeCodec: UserPreferences.shared.videoYoutubeCodec,
                    videoDownloadQuality: UserPreferences.shared.videoDownloadQuality,
                    audioFormat: UserPreferences.shared.audioFormat,
                    audioOnly: audioOnly,
                    videoTiktokWatermarkDisabled: UserPreferences.shared.videoTiktokWatermarkDisabled,
                    audioTiktokFullAudio: UserPreferences.shared.audioTiktokFullAudio,
                    audioMute: UserPreferences.shared.audioMute,
                    audioYoutubeTrack: UserPreferences.shared.audioYoutubeTrack,
                    videoTwitterConvertGifsToGif: UserPreferences.shared.videoTwitterConvertGifsToGif,
                    videoVimeoDownloadType: UserPreferences.shared.videoVimeoDownloadType
                )
                let request = REST.HTTPRequest(host: "co.wuk.sh", path: "/api/json", method: .post, body: REST.JSONBody(cobaltRequest))

                log(.info, "🏁 Start fetching Download URL using request: \(request)")
                let response = try await REST.Loader.shared.load(using: request)
                let cobaltResponse: POSTCobaltResponse = try response.decode()
                log(.info, "✅ Finished fetching Download URL with response: \(response)")

                // If contains picker, then download everything
                if let streamURL = cobaltResponse.url {
                    await DownloadService.shared.download(using: url, streamURL: streamURL, mediaService: mediaService, metadata: metadata)
                } else {
                    await withTaskGroup(of: Void.self) { group in
                        if let audioStream = cobaltResponse.audio {
                            group.addTask {
                                await DownloadService.shared.download(using: url, streamURL: audioStream, mediaService: mediaService, metadata: metadata)
                            }
                        }

                        for picker in cobaltResponse.picker {
                            group.addTask {
                                await DownloadService.shared.download(using: url, streamURL: picker.url, mediaService: mediaService, metadata: metadata)
                            }
                        }
                    }
                }
            } catch {
                log(.error, error)
                errorDetails = .default
            }
            self.isLoading = false
        }
        downloadTasks.append(downloadTask)
    }

    func cancel(item: DownloadItem) {
        DownloadService.shared.cancel(using: item.streamURL)
    }

    func delete(item: DownloadItem) {
        DownloadService.shared.delete(using: item.streamURL)
    }

    func resume(item: DownloadItem) {
        DownloadService.shared.resume(using: item.streamURL)
    }
}
