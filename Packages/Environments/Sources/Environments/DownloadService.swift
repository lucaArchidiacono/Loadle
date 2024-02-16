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
import Generator
import Models
import LinkPresentation
import Combine

@Observable
@MainActor
public final class DownloadService {
	public enum ServiceError: Error, CustomStringConvertible {
		case noRedirectURL(inside: REST.HTTPResponse<POSTCobaltResponse>)

		public var description: String {
			let description = "\(type(of: self))."
			switch self {
			case .noRedirectURL(let response):
				return description + "noRedirectURL: " + "There is no redirect URL inside: \(response)"
			}
		}
	}

	@Observable
	public class DownloadServiceStore {
		static func loadBaseURL() throws -> URL {
			let downloadsURL = try FileManager.default
				.url(for: .documentDirectory,
					 in: .userDomainMask,
					 appropriateFor: .documentsDirectory,
					 create: true)
				.appendingPathComponent("DOWNLOADS", conformingTo: .directory)

			if !FileManager.default.fileExists(atPath: downloadsURL.standardizedFileURL.path(percentEncoded: false)) {
				try FileManager.default.createDirectory(at: downloadsURL, withIntermediateDirectories: true, attributes: nil)
			}

			return downloadsURL
		}

		public var downloads: [DownloadItem]

		@ObservationIgnored
		private var mediaURLRegistry: [DownloadItem.ID: URL]
		@ObservationIgnored
		private var queue = DispatchQueue(label: "Service.Download.Store")

		init() {
			self.downloads = []
			self.mediaURLRegistry = [:]
		}

		func addNew(download: DownloadItem) {
			queue.sync {
				downloads.append(download)
			}
		}
		
		func delete(with id: DownloadItem.ID) {
			queue.sync {
				guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
				downloads.remove(at: index)
				mediaURLRegistry.removeValue(forKey: id)
			}
		}

		func complete(with id: DownloadItem.ID, result: Result<Void, Error>) {
			queue.sync {
				guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }

				switch result {
				case .success:
					downloads[index] = downloads[index].update(state: .completed)
					downloads[index].onComplete?(.success(()))
				case .failure(let error):
					downloads[index] = downloads[index].update(state: .failed)
					downloads[index].onComplete?(.failure(error))
				}
			}
		}

		func update(with id: DownloadItem.ID, state: DownloadItem.State) {
			queue.sync {
				guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
				downloads[index] = downloads[index].update(state: state)
			}
		}

		func update(with id: DownloadItem.ID, mediaDownloadInformation: DownloadItem.MediaDownloadInformation) {
			queue.sync {
				guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
				downloads[index] = downloads[index].update(mediaDownloadInformation: mediaDownloadInformation)
			}
		}

		func get(with id: DownloadItem.ID) -> (DownloadItem?, URL?) {
			queue.sync {
				guard let index = downloads.firstIndex(where: { $0.id == id }) else { return (nil, nil) }
				return (downloads[index], mediaURLRegistry[id])
			}
		}
		
		func get(with id: DownloadItem.ID) -> URL? {
			queue.sync { mediaURLRegistry[id] }
		}
		
		func get(with id: DownloadItem.ID) -> DownloadItem? {
			queue.sync {
				guard let index = downloads.firstIndex(where: { $0.id == id }) else { return nil }
				return downloads[index]
			}
		}

		func addNew(mediaURL: URL, using id: DownloadItem.ID) {
			queue.sync {
				mediaURLRegistry[id] = mediaURL
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

	public let store: DownloadServiceStore = DownloadServiceStore()

	@ObservationIgnored
	private var backgroundCompletionHandlers: [() -> Void] = []
	@ObservationIgnored
	private let loader = REST.Loader.shared
	@ObservationIgnored
	private lazy var mediaDownloader: REST.Downloader = {
		return REST.Downloader.shared(withDebuggingBackgroundTasks: debuggingBackgroundTasks)
	}()
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
	}

	public func download(using url: URL, preferences: UserPreferences, audioOnly: Bool, onComplete: @escaping (Result<Void, Error>) -> Void) {
		let provider = LPMetadataProvider()

		provider.startFetchingMetadata(for: url) { [weak self] metadata, error in
			guard let self else { return }
			if let error {
				onComplete(.failure(error))
				return
			}

			guard let metadata else { return }
			
			let download = DownloadItem(remoteURL: url, metaData: metadata, onComplete: onComplete)
			store.addNew(download: download)

			startDownload(using: download.remoteURL, id: download.id, preferences: preferences, audioOnly: audioOnly)
		}
	}

	public func delete(id: DownloadItem.ID) {
		if let mediaURL: URL = store.get(with: id) {
			mediaDownloader.deleteDownload(with: mediaURL)
		}
		store.delete(with: id)
	}

	public func cancel(id: DownloadItem.ID) {
		if let mediaURL: URL = store.get(with: id) {
			mediaDownloader.cancelDownload(with: mediaURL)
		}
		store.update(with: id, state: .cancelled)
	}

	public func resume(id: DownloadItem.ID) {
		let (downloadItem, mediaURL) = store.get(with: id)
		if let mediaURL {
			mediaDownloader.resumeDownload(with: mediaURL)
		} else if let downloadItem, let mediaDownloadInformation = downloadItem.mediaDownloadInformation {
			// If there is no mediaURL we can assume that it was cancelled before starting the actual Media Download.
			// Therefore we will just recall downloadMedia(id: downloadItem.id, mediaDownloadInformation: mediaDownloadInformation)
			downloadMedia(id: downloadItem.id, mediaDownloadInformation: mediaDownloadInformation)
		}
	}

	public func addBackgroundCompletionHandler(handler: @escaping () -> Void) {
		backgroundCompletionHandlers.append(handler)
	}
}

// MARK: - Private API
extension DownloadService {
	private func startDownload(using url: URL, id: DownloadItem.ID, preferences: UserPreferences, audioOnly: Bool) {
		downloadWebsite(using: url, id: id) { [weak self] result in
			guard let self else { return }
			
			switch result {
			case .success:
				guard let mediaService = MediaService.allCases.first(where: { url.matchesRegex(pattern: $0.regex) }) else {
					// Save to local DB as Asset without Media
					self.store.complete(with: id, result: .success(()))
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

				let mediaDownloadInformation = DownloadItem.MediaDownloadInformation(mediaService: mediaService, cobaltRequest: cobaltRequest)
				store.update(with: id, mediaDownloadInformation: mediaDownloadInformation)

				self.downloadMedia(id: id, mediaDownloadInformation: mediaDownloadInformation)
			case .failure(let error):
				self.store.complete(with: id, result: .failure(error))
			}
		}
	}

	private func downloadWebsite(using url: URL, id: DownloadItem.ID, onComplete: @escaping (Result<Void, Error>) -> Void) {
		// Download Website as archive
		websiteLoader.download(url: url) { [weak self] result in
			guard let self else { return }
			switch result {
			case .success(let representations):
				log(.debug, "Downloaded following representations: \(representations)")

				let currentBytes = representations.reduce(0) { partialResult, representation in
					return partialResult + representation.size
				}

				store.update(with: id, state: .progress(currentBytes: Double(currentBytes), totalBytes: -1.0))

				onComplete(.success(()))
			case .failure(let error):
				onComplete(.failure(error))
			}
		}
	}

	private func downloadMedia(id: DownloadItem.ID, mediaDownloadInformation: DownloadItem.MediaDownloadInformation) {
		let request = REST.HTTPRequest(host: "co.wuk.sh", path: "/api/json", method: .post, body: REST.JSONBody(mediaDownloadInformation.cobaltRequest))
		loader.load(using: request) { [weak self] (result: Result<REST.HTTPResponse<POSTCobaltResponse>, REST.HTTPError<POSTCobaltResponse>>) in
			guard let self else { return }
			switch result {
			case .success(let response):
				self.downloadMedia(id: id, redirectedURL: response.body.url!)
			case .failure(let error):
				self.store.complete(with: id, result: .failure(error))
			}
		}
	}

	private func downloadMedia(id: DownloadItem.ID, redirectedURL: URL) {
		store.addNew(mediaURL: redirectedURL, using: id)

		mediaDownloader.download(url: redirectedURL) { [weak self] newState in
			self?.process(newState, for: id)
		}
	}

	private func process(_ state: REST.Downloader.ResultState, for id: DownloadItem.ID) {
		switch state {
		case .progress(let currentBytes, let totalBytes):
			store.update(with: id, state: .progress(currentBytes: currentBytes, totalBytes: totalBytes))
		case .success(let url):
			log(.info, "Successfully downloaded the media: \(url)")
			store.complete(with: id, result: .success(()))
		case .failed(let error):
			log(.error, "The download failed due to the following error: \(error)")
			store.complete(with: id, result: .failure(error))
		case .cancelled:
			store.update(with: id, state: .cancelled)
		}
	}
}
