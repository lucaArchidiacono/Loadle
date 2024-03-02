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

@MainActor
@Observable
final class DownloadViewModel {
    public var errorDetails: ErrorDetails?
	public var downloads: [DownloadItem] = []

    public var isLoading: Bool = false
    public var audioOnly: Bool = false

    private let downloadService: DownloadService = .shared

    init() {
		downloadService.onUpdate = { [weak self] downloads in
			guard let self else { return }
			Task { @MainActor in
				self.downloads = downloads
			}
		}
	}

    func startDownload(using url: String, preferences: UserPreferences, router: Router) {
        guard let url = URL(string: url), UIApplication.shared.canOpenURL(url) else {
            errorDetails = ErrorDetails(
                title: L10n.invalidUrlTitle,
                description: L10n.invalidUrlWrongDescription,
                actions: [.primary(title: L10n.ok)]
            )
            return
        }

        guard !isLoading else { return }
        isLoading = true
		let preferences = Preferences(audioOnly: audioOnly,
									  filenameStyle: preferences.filenameStyle,
									  videoDownloadQuality: preferences.videoDownloadQuality,
									  videoYoutubeCodec: preferences.videoYoutubeCodec,
									  videoVimeoDownloadType: preferences.videoVimeoDownloadType,
									  videoTiktokWatermarkDisabled: preferences.videoTiktokWatermarkDisabled,
									  videoTwitterConvertGifsToGif: preferences.videoTwitterConvertGifsToGif,
									  audioFormat: preferences.audioFormat,
									  audioYoutubeTrack: preferences.audioYoutubeTrack,
									  audioMute: preferences.audioMute,
									  audioTiktokFullAudio: preferences.audioTiktokFullAudio)
        downloadService.download(using: url, preferences: preferences) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success:
                log(.info, "Successfully launched a download!")
            case let .failure(error):
				if let downloadServiceError = error as? DownloadService.Error {
					switch downloadServiceError {
					case .noValidMediaService:
						errorDetails = ErrorDetails(title: L10n.invalidUrlTitle,
													description: L10n.mediaServicesTitle,
													actions: [.primary(title: L10n.ok)])
					}
				} else {
					errorDetails = buildGenericErrorDetails(using: error, router: router)
				}
            }
        }
    }

	func cancel(item: DownloadItem) {
		downloadService.cancel(item: item)
	}

	func delete(item: DownloadItem) {
		downloadService.delete(item: item)
	}

	func resume(item: DownloadItem) {
		downloadService.resume(item: item)
	}
}

extension DownloadViewModel {
    private func buildGenericErrorDetails(using _: Error, router _: Router) -> ErrorDetails {
        return ErrorDetails(
            title: L10n.somethingWentWrongTitle,
            description: L10n.somethingWentWrongDescription,
            actions: [.primary(title: L10n.ok)]
        )
    }
}
