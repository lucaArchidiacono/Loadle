//
//  DownloadService.swift
//  Loadle
//
//  Created by Luca Archidiacono on 14.02.2024.
//

import Combine
import Constants
import Foundation
import Generator
import LinkPresentation
import Logger
import Models
import REST
import SwiftUI

@Observable
@MainActor
public final class DownloadService {
	public enum Error: Swift.Error, CustomStringConvertible {
		case noValidMediaService(url: URL)

        public var description: String {
            let description = "\(type(of: self))."
            switch self {
			case let .noValidMediaService(url):
				return description + "noValidMediaService: " + "No valid `MediaService` found given the url: \(url)"
            }
        }
    }

    public var debuggingBackgroundTasks: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }

	@Observable
	public final class DownloadServiceStore {
		public var downloads: [DownloadItem] = []

		@ObservationIgnored
		private var queue = DispatchQueue(label: "Service.Download.Store")

		func setup(downloadTasks: [REST.Download]) {
			StorageService.shared.downloadItemStorage.loadAll()
				.filter { downloadItem in
					!downloadTasks.contains(where: { $0.url == downloadItem.streamURL })
				}
				.forEach {
					StorageService.shared.downloadItemStorage.delete($0.id)
				}

			self.downloads = StorageService.shared.downloadItemStorage.loadAll()
		}

		func addNew(_ downloadItem: DownloadItem) {
			queue.sync {
				downloads.append(downloadItem)
				StorageService.shared.downloadItemStorage.store(downloadItem: downloadItem)
			}
		}

		func delete(_ downloadItem: DownloadItem) {
			queue.sync {
				guard let index = downloads.firstIndex(where: { $0.id == downloadItem.id }) else {
					log(.warning, "Was not able to find and delete `DownloadItem` with id: \(downloadItem.id)")
					return
				}

				downloads.remove(at: index)
				StorageService.shared.downloadItemStorage.delete(downloadItem.id)
			}
		}

		func update(using url: URL, state: DownloadItem.State) {
			queue.sync {
				guard let index = downloads.firstIndex(where: { $0.streamURL == url }) else {
					log(.warning, "Was not able to find and update `DownloadItem` with url: \(url)")
					return
				}

				let updatedDownloadItem = downloads[index].update(state: state)
				downloads[index] = updatedDownloadItem
				StorageService.shared.downloadItemStorage.store(downloadItem: updatedDownloadItem)
			}
		}
	}

	public let store = DownloadServiceStore()
	
    @ObservationIgnored
    private var backgroundCompletionHandlers: [() -> Void] = []
    @ObservationIgnored
    private let loader = REST.Loader.shared
    @ObservationIgnored
    private lazy var mediaDownloader: REST.Downloader = .shared(withDebuggingBackgroundTasks: debuggingBackgroundTasks)
    @ObservationIgnored
    private let websiteLoader = WebsiteService.shared
    @ObservationIgnored
    private let subscriptions = Set<AnyCancellable>()

    public static let shared = DownloadService()

    private init() {
        mediaDownloader.backgroundCompletionHandler = { [weak self] in
            self?.backgroundCompletionHandlers.forEach { $0() }
            self?.backgroundCompletionHandlers = []
        }

		mediaDownloader.getAllDownloads { [weak self] downloadTasks in
			guard let self else { return }
			self.store.setup(downloadTasks: downloadTasks)

			downloadTasks.forEach { download in
				download.completionHandler = { newState in
					self.process(url: download.url, newState: newState)
				}
			}
		}
    }

	public func download(using url: URL, preferences: UserPreferences, audioOnly: Bool, onComplete: @escaping (Result<Void, Swift.Error>) -> Void) {
		guard let mediaService = MediaService.allCases.first(where: { url.matchesRegex(pattern: $0.regex) }) else {
			onComplete(.failure(Error.noValidMediaService(url: url)))
			return
		}

		fetchMetaData(using: url) { [weak self] result in
			guard let self else { return }
			
			switch result {
			case .success(let metadata):
				self.downloadMedia(using: url,
							  preferences: preferences,
							  audioOnly: audioOnly,
							  metadata: metadata,
							  service: mediaService,
							  onComplete: onComplete)
			case .failure(let error):
				onComplete(.failure(error))
			}
		}
    }

	private func fetchMetaData(using url: URL, onComplete: @escaping (Result<LPLinkMetadata, Swift.Error>) -> Void) {
		let provider = LPMetadataProvider()

		provider.startFetchingMetadata(for: url) { metadata, error in
			if let error {
				log(.error, error)
				onComplete(.failure(error))
				return
			}

			log(.debug, "Fetched metadata successfully: \(metadata!)")
			onComplete(.success(metadata!))
		}
	}

	private func downloadMedia(using url: URL, 
							   preferences: UserPreferences,
							   audioOnly: Bool,
							   metadata: LPLinkMetadata,
							   service: MediaService,
							   onComplete: @escaping (Result<Void, Swift.Error>) -> Void) {
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
			guard let self else { return }
			switch result {
			case let .success(response):
				let streamURL = response.body.url!
				let downloadItem = DownloadItem(remoteURL: url, streamURL: streamURL, service: service, metadata: metadata)
				store.addNew(downloadItem)

				mediaDownloader.download(url: streamURL) { newState in
					self.process(url: streamURL, newState: newState)
				}

				onComplete(.success(()))
			case let .failure(error):
				onComplete(.failure(error))
			}
		}
	}

	public func delete(item: DownloadItem) {
		mediaDownloader.deleteDownload(with: item.remoteURL)
    }

    public func cancel(item: DownloadItem) {
		mediaDownloader.cancelDownload(with: item.remoteURL)
    }

    public func resume(item: DownloadItem) {
		mediaDownloader.resumeDownload(with: item.remoteURL)
    }

    public func addBackgroundCompletionHandler(handler: @escaping () -> Void) {
        backgroundCompletionHandlers.append(handler)
    }
}

// MARK: - Private API

extension DownloadService {
	private func process(url: URL, newState: REST.Downloader.ResultState) {
		switch newState {
		case .pending: break
		case let .progress(currentBytes, totalBytes):
			store.update(using: url, state: .progress(currentBytes: currentBytes, totalBytes: totalBytes))
		case let .success(fileURL):
			log(.info, "Successfully downloaded the media: \(url)")
			store.update(using: url, state: .completed)
		case let .failed(error):
			log(.error, "The download failed due to the following error: \(error)")
			store.update(using: url, state: .failed)
		case .cancelled:
			store.update(using: url, state: .cancelled)
		}
	}
}
