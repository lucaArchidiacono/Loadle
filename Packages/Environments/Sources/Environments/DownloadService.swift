//
//  DownloadService.swift
//  Loadle
//
//  Created by Luca Archidiacono on 14.02.2024.
//

import Foundation
import LinkPresentation
import Logger
import Models
import REST
import LocalStorage

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
			PersistenceController.shared.downloadItem.loadAll()
				.filter { downloadItem in
					!downloadTasks.contains(where: { $0.url == downloadItem.streamURL })
				}
				.forEach {
					PersistenceController.shared.downloadItem.delete($0.id)
				}

			self.downloads = PersistenceController.shared.downloadItem.loadAll()
		}

		func addNew(_ downloadItem: DownloadItem) {
			queue.sync {
				downloads.append(downloadItem)
				PersistenceController.shared.downloadItem.store(downloadItem: downloadItem)
			}
		}

		func delete(using url: URL) {
			queue.sync {
				guard let index = downloads.firstIndex(where: { $0.streamURL == url }) else {
					log(.warning, "Was not able to find and delete `DownloadItem` with url: \(url)")
					return
				}

				let downloadItem = downloads[index]
				downloads.remove(at: index)
				PersistenceController.shared.downloadItem.delete(downloadItem.id)
			}
		}

		@discardableResult
		func update(using url: URL, state: DownloadItem.State) -> DownloadItem? {
			queue.sync {
				guard let index = downloads.firstIndex(where: { $0.streamURL == url }) else {
					log(.warning, "Was not able to find and update `DownloadItem` with url: \(url)")
					return nil
				}

				let updatedDownloadItem = downloads[index].update(state: state)
				downloads[index] = updatedDownloadItem
				PersistenceController.shared.downloadItem.store(downloadItem: updatedDownloadItem)
				return updatedDownloadItem
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

	public func download(using url: URL, audioOnly: Bool, onComplete: @escaping (Result<Void, Swift.Error>) -> Void) {
		guard let mediaService = MediaService.allCases.first(where: { url.matchesRegex(pattern: $0.regex) }) else {
			onComplete(.failure(Error.noValidMediaService(url: url)))
			return
		}

		MetadataService.shared.fetch(using: url) { [weak self] result in
			guard let self else { return }
			switch result {
			case .success(let metadata):
				self.downloadMedia(using: metadata.url!,
								   audioOnly: audioOnly,
								   metadata: metadata,
								   service: mediaService,
								   onComplete: onComplete)
			case .failure(let error):
				onComplete(.failure(error))
			}
		}
    }

	private func downloadMedia(using url: URL,
							   audioOnly: Bool,
							   metadata: LPLinkMetadata,
							   service: MediaService,
							   onComplete: @escaping (Result<Void, Swift.Error>) -> Void) {
		let cobaltRequest = CobaltRequest(
			url: DataTransformer.URL.transform(url, service: service),
			vCodec: UserPreferences.shared.videoYoutubeCodec,
			vQuality: UserPreferences.shared.videoDownloadQuality,
			aFormat: UserPreferences.shared.audioFormat,
			isAudioOnly: audioOnly,
			isNoTTWatermark: UserPreferences.shared.videoTiktokWatermarkDisabled,
			isTTFullAudio: UserPreferences.shared.audioTiktokFullAudio,
			isAudioMuted: UserPreferences.shared.audioMute,
			dubLang: UserPreferences.shared.audioYoutubeTrack == .original ? false : true,
			disableMetadata: false,
			twitterGif: UserPreferences.shared.videoTwitterConvertGifsToGif,
			vimeoDash: UserPreferences.shared.videoVimeoDownloadType == .progressive ? nil : true
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
				log(.error, "Failed to fetch media stream URL given the following error: \(error)")
				onComplete(.failure(error))
			}
		}
	}

	public func delete(item: DownloadItem) {
		mediaDownloader.deleteDownload(with: item.streamURL)
		store.delete(using: item.streamURL)
    }

    public func cancel(item: DownloadItem) {
		mediaDownloader.cancelDownload(with: item.streamURL)
    }

    public func resume(item: DownloadItem) {
		mediaDownloader.resumeDownload(with: item.streamURL)
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
			log(.info, "Successfully downloaded the media: \(fileURL)")
			guard let updatedDownloadItem = store.update(using: url, state: .completed) else { return }
			MediaAssetService.shared.store(downloadItem: updatedDownloadItem, originalFileURL: fileURL)
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
				self?.store.delete(using: url)
			}
		case let .failed(error):
			log(.error, "The download failed due to the following error: \(error)")
			store.update(using: url, state: .failed)
		case .cancelled:
			log(.warning, "Download with has been cancelled with following url: \(url)")
			store.update(using: url, state: .cancelled)
		}
	}
}
