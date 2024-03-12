//
//  DownloadViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Environments
import Foundation
import Generator
import Logger
import Models
import SwiftUI
import REST

@MainActor
@Observable
final class DownloadViewModel {
    public var errorDetails: ErrorDetails?
	public var audioOnly: Bool = false
	public var downloadItems: [DownloadItem] = []

	@ObservationIgnored
	private let loader: REST.Loader = .shared
	@ObservationIgnored
    private let downloadService: DownloadService = .shared
	@ObservationIgnored
	private let metadataService: MetadataService = .shared


	init() {
		Task { @MainActor in
			for await downloadItems in await downloadService.downloads() {
				self.downloadItems = downloadItems
			}
		}
	}

    func startDownload(using url: String) {
        guard let url = URL(string: url), UIApplication.shared.canOpenURL(url) else {
            errorDetails = ErrorDetails(
                title: L10n.invalidUrlTitle,
                description: L10n.invalidUrlWrongDescription,
                actions: [.primary(title: L10n.ok)]
            )
            return
        }

		guard let mediaService = MediaService.allCases.first(where: { url.matchesRegex(pattern: $0.regex) }) else {
			errorDetails = ErrorDetails(
				title: L10n.invalidUrlTitle,
				description: L10n.mediaServicesTitle,
				actions: [.primary(title: L10n.ok)])
			return
		}

		Task {
			do {
				let metadata = try await metadataService.fetch(using: url)

				guard let url = metadata.url else {
					log(.error, "Was not able to fetch url from metadata!")
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
					videoVimeoDownloadType: UserPreferences.shared.videoVimeoDownloadType)
				let request = REST.HTTPRequest(host: "co.wuk.sh", path: "/api/json", method: .post, body: REST.JSONBody(cobaltRequest))

				let response = try await loader.load(using: request)
				let cobaltResponse: POSTCobaltResponse = try response.decode()
				let streamURL = cobaltResponse.url!
				await downloadService.download(using: url, streamURL: streamURL, mediaService: mediaService, metadata: metadata)
			} catch {
				log(.error, error)
			}
		}
    }

	func cancel(item: DownloadItem) {
		downloadService.cancel(using: item.streamURL)
	}

	func delete(item: DownloadItem) {
		downloadService.delete(using: item.streamURL)
	}

	func resume(item: DownloadItem) {
		downloadService.resume(using: item.streamURL)
	}
}

extension DownloadViewModel {
    private func buildGenericErrorDetails(using _: Error) -> ErrorDetails {
        return ErrorDetails(
            title: L10n.somethingWentWrongTitle,
            description: L10n.somethingWentWrongDescription,
            actions: [.primary(title: L10n.ok)]
        )
    }
}
