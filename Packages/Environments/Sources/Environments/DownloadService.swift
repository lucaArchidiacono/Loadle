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

	public final class DownloadServiceStore {
		private var downloads: [DownloadItem] = [] {
			didSet {
				onUpdate?(downloads)
			}
		}
		private var queue = DispatchQueue(label: "Service.Download.Store")
		fileprivate var onUpdate: (([DownloadItem]) -> Void)? {
			didSet {
				onUpdate?(downloads)
			}
		}

		func setup(mediaDownloader: REST.Downloader, completion: @escaping ([REST.Download]) -> Void) {
			let group = DispatchGroup()
			queue.async { [weak self] in
				guard let self else { return }
				group.enter()
				mediaDownloader.getAllDownloads { downloadTasks in
					defer { group.leave() }

					PersistenceController.shared.downloadItem.loadAll()
						.filter { downloadItem in
							!downloadTasks.contains(where: { $0.url == downloadItem.streamURL })
						}
						.forEach {
							PersistenceController.shared.downloadItem.delete($0.id)
						}

					self.downloads = PersistenceController.shared.downloadItem.loadAll()

					completion(downloadTasks)
				}
				group.wait()
			}
		}
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

	private let store = DownloadServiceStore()
    private let loader = REST.Loader.shared
    private let websiteLoader = WebsiteService.shared
	private let group = DispatchGroup()

	private var backgroundCompletionHandlers: [() -> Void] = []
	private var queue = DispatchQueue(label: "Service.Download")

    private lazy var mediaDownloader: REST.Downloader = .shared(withDebuggingBackgroundTasks: debuggingBackgroundTasks)

	public var debuggingBackgroundTasks: Bool {
		#if DEBUG
			return true
		#else
			return false
		#endif
	}

    public static let shared = DownloadService()

	public var onUpdate: (([DownloadItem]) -> Void)? {
		didSet {
			store.onUpdate = { [weak self] downloads in
				guard let self else { return }
				onUpdate?(downloads)
			}
		}
	}

    private init() {
        mediaDownloader.backgroundCompletionHandler = { [weak self] in
            self?.backgroundCompletionHandlers.forEach { $0() }
            self?.backgroundCompletionHandlers = []
        }

		store.setup(mediaDownloader: mediaDownloader) { [weak self] downloadTasks in
			guard let self else { return }
			downloadTasks.forEach { downloadTask in
				downloadTask.completionHandler = { newState in
					self.process(url: downloadTask.url, newState: newState)
				}
			}
		}
    }

	public func download(using url: URL, preferences: Preferences, onComplete: @escaping (Result<Void, Swift.Error>) -> Void) {
		guard let mediaService = MediaService.allCases.first(where: { url.matchesRegex(pattern: $0.regex) }) else {
			onComplete(.failure(Error.noValidMediaService(url: url)))
			return
		}

		queue.async { [weak self] in
			guard let self else { return }
			group.enter()
			MetadataService.shared.fetch(using: url) { result in
				switch result {
				case .success(let metadata):
					self.downloadMedia(using: metadata.url!,
									   preferences: preferences,
									   metadata: metadata,
									   service: mediaService) { result in
						switch result {
						case .success:
							onComplete(.success(()))
						case .failure(let error):
							onComplete(.failure(error))
						}
						self.group.leave()
					}
				case .failure(let error):
					onComplete(.failure(error))
					self.group.leave()
				}
			}
			group.wait()
		}
    }

	private func downloadMedia(using url: URL,
							   preferences: Preferences,
							   metadata: LPLinkMetadata,
							   service: MediaService,
							   onComplete: @escaping (Result<Void, Swift.Error>) -> Void) {
		let cobaltRequest = CobaltRequest(
			url: DataTransformer.URL.transform(url, service: service),
			vCodec: preferences.videoYoutubeCodec,
			vQuality: preferences.videoDownloadQuality,
			aFormat: preferences.audioFormat,
			isAudioOnly: preferences.audioOnly,
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
				log(.error, "Failed to fetch media stream URL given the following error: \(error)")
				onComplete(.failure(error))
			}
		}
	}

	public func delete(item: DownloadItem) {
		queue.sync {
			mediaDownloader.deleteDownload(with: item.streamURL)
			store.delete(using: item.streamURL)
		}
    }

    public func cancel(item: DownloadItem) {
		queue.sync {
			mediaDownloader.cancelDownload(with: item.streamURL)
		}
    }

    public func resume(item: DownloadItem) {
		queue.sync {
			mediaDownloader.resumeDownload(with: item.streamURL)
		}
    }

    public func addBackgroundCompletionHandler(handler: @escaping () -> Void) {
        backgroundCompletionHandlers.append(handler)
    }
}

// MARK: - Private API

extension DownloadService {
	private func process(url: URL, newState: REST.Downloader.ResultState) {
		queue.async { [weak self] in
			guard let self else { return }

			switch newState {
			case .pending: break
			case let .progress(currentBytes, totalBytes):
				self.store.update(using: url, state: .progress(currentBytes: currentBytes, totalBytes: totalBytes))
			case let .success(fileURL):
				log(.info, "Successfully downloaded the media: \(fileURL)")
				guard let updatedDownloadItem = self.store.update(using: url, state: .completed) else { return }
				MediaAssetService.shared.store(downloadItem: updatedDownloadItem, originalFileURL: fileURL)
				self.queue.asyncAfter(deadline: .now() + 1.0) {
					self.store.delete(using: url)
				}
			case let .failed(error):
				log(.error, "The download failed due to the following error: \(error)")
				self.store.update(using: url, state: .failed)
			case .cancelled:
				log(.warning, "Download with has been cancelled with following url: \(url)")
				self.store.update(using: url, state: .cancelled)
			}
		}
	}
}
