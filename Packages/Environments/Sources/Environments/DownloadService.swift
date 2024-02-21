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
    public enum ServiceError: Error, CustomStringConvertible {
        case noRedirectURL(inside: REST.HTTPResponse<POSTCobaltResponse>)

        public var description: String {
            let description = "\(type(of: self))."
            switch self {
            case let .noRedirectURL(response):
                return description + "noRedirectURL: " + "There is no redirect URL inside: \(response)"
            }
        }
    }

    @Observable
    public class DownloadServiceStore {
        private static func fileURL() throws -> URL {
            let downloadsURL = try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: .documentsDirectory,
                     create: true)
                .appendingPathComponent("DOWNLOADS", conformingTo: .directory)

            if !FileManager.default.fileExists(atPath: downloadsURL.standardizedFileURL.path(percentEncoded: false)) {
                try FileManager.default.createDirectory(at: downloadsURL, withIntermediateDirectories: true, attributes: nil)
            }

            return downloadsURL.appendingPathComponent("downloadItems.data", conformingTo: .data)
        }

        public var downloads: [DownloadItem] = []

        @ObservationIgnored
        private var mediaURLRegistry: [DownloadItem.ID: URL] = [:]
        @ObservationIgnored
        private var queue = DispatchQueue(label: "Service.Download.Store")

        init() {
            //			self.downloads = loadFromStorage()
            //			self.mediaURLRegistry = self.downloads.reduce(into: [DownloadItem.ID: URL](), { partialResult, downloadItem in
            //				partialResult[downloadItem.id] = downloadItem.remoteURL
            //			})
        }

        func store(download: DownloadItem) {
            queue.sync {
                downloads.append(download)
                //				storeIntoStorage()
            }
        }

        func store(mediaURL: URL, using id: DownloadItem.ID) {
            queue.sync {
                mediaURLRegistry[id] = mediaURL
            }
        }

        func get(with id: DownloadItem.ID) -> URL? {
            queue.sync {
                mediaURLRegistry[id]
            }
        }

        func delete(with id: DownloadItem.ID) {
            queue.sync {
                guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
                downloads.remove(at: index)
                //				storeIntoStorage()
                mediaURLRegistry.removeValue(forKey: id)
            }
        }

        func update(with id: DownloadItem.ID, result: Result<Void, Error>) {
            queue.sync {
                guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }

                switch result {
                case .success:
                    downloads[index] = downloads[index].update(state: .completed)
                    //					storeIntoStorage()
                    downloads[index].onComplete?(.success(()))
                case let .failure(error):
                    downloads[index] = downloads[index].update(state: .failed)
                    //					storeIntoStorage()
                    downloads[index].onComplete?(.failure(error))
                }
            }
        }

        func update(with id: DownloadItem.ID, state: DownloadItem.State) {
            queue.sync {
                guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
                downloads[index] = downloads[index].update(state: state)
                //				storeIntoStorage()
            }
        }

        func update(with id: DownloadItem.ID, mediaInformation: DownloadItem.MediaInformation) {
            queue.sync {
                guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
                downloads[index] = downloads[index].update(mediaInformation: mediaInformation)
                //				storeIntoStorage()
            }
        }

        private func storeIntoStorage() {
            guard let data = try? JSONEncoder().encode(downloads),
                  let outfile = try? Self.fileURL()
            else { return }

            try? data.write(to: outfile)
        }

        private func loadFromStorage() -> [DownloadItem] {
            guard let outfile = try? Self.fileURL(),
                  let data = try? Data(contentsOf: outfile)
            else { return [] }

            let downloadItems = try? JSONDecoder().decode([DownloadItem].self, from: data)

            return downloadItems ?? []
        }
    }

    public var debuggingBackgroundTasks: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }

    public let store: DownloadServiceStore = .init()

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
    }

    public func download(using url: URL, preferences: UserPreferences, audioOnly: Bool, onComplete: @escaping (Result<Void, Error>) -> Void) {
        let provider = LPMetadataProvider()

        provider.startFetchingMetadata(for: url) { [weak self] metadata, error in
            guard let self else { return }
            if let error {
                log(.error, error)
                onComplete(.failure(error))
                return
            }

            guard let metadata else { return }
            log(.debug, "Fetched metadata successfully: \(metadata)")

            startDownload(using: url, metadata: metadata, preferences: preferences, audioOnly: audioOnly, onComplete: onComplete)
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
    }

    public func resume(id: DownloadItem.ID) {
        if let mediaURL: URL = store.get(with: id) {
            mediaDownloader.resumeDownload(with: mediaURL)
        }
    }

    public func addBackgroundCompletionHandler(handler: @escaping () -> Void) {
        backgroundCompletionHandlers.append(handler)
    }
}

// MARK: - Private API

extension DownloadService {
    private func startDownload(using url: URL, metadata: LPLinkMetadata, preferences: UserPreferences, audioOnly: Bool, onComplete: @escaping (Result<Void, Error>) -> Void) {
        downloadWebsite(using: url) { [weak self] result in
            guard let self else { return }

            switch result {
            case let .success(websiteRepresentations):
                let download = DownloadItem(remoteURL: url, metaData: metadata, websiteRepresentations: websiteRepresentations, onComplete: onComplete)
                store.store(download: download)

                guard let mediaService = MediaService.allCases.first(where: { url.matchesRegex(pattern: $0.regex) }) else {
                    // Save to local DB as Asset without Media
                    self.store.update(with: download.id, result: .success(()))
                    return
                }

                let cobaltRequest = CobaltRequest(
                    url: download.remoteURL,
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

                let mediaInformation = DownloadItem.MediaInformation(mediaService: mediaService, cobaltRequest: cobaltRequest)
                store.update(with: download.id, mediaInformation: mediaInformation)

                self.downloadMedia(id: download.id, mediaInformation: mediaInformation)
            case let .failure(error):
                onComplete(.failure(error))
            }
        }
    }

    private func downloadWebsite(using url: URL, onComplete: @escaping (Result<[WebsiteRepresentation], Error>) -> Void) {
        // Download Website as archive
        websiteLoader.download(url: url) { result in
            switch result {
            case let .success(representations):
                log(.debug, "Downloaded following representations: \(representations)")
                onComplete(.success(representations))
            case let .failure(error):
                log(.error, error)
                onComplete(.failure(error))
            }
        }
    }

    private func downloadMedia(id: DownloadItem.ID, mediaInformation: DownloadItem.MediaInformation) {
        let request = REST.HTTPRequest(host: "co.wuk.sh", path: "/api/json", method: .post, body: REST.JSONBody(mediaInformation.cobaltRequest))
        loader.load(using: request) { [weak self] (result: Result<REST.HTTPResponse<POSTCobaltResponse>, REST.HTTPError<POSTCobaltResponse>>) in
            guard let self else { return }
            switch result {
            case let .success(response):
                self.downloadMedia(id: id, redirectedURL: response.body.url!)
            case let .failure(error):
                self.store.update(with: id, result: .failure(error))
            }
        }
    }

    private func downloadMedia(id: DownloadItem.ID, redirectedURL: URL) {
        store.store(mediaURL: redirectedURL, using: id)

        mediaDownloader.download(url: redirectedURL) { [weak self] newState in
            self?.process(newState, for: id)
        }
    }

    private func process(_ state: REST.Downloader.ResultState, for id: DownloadItem.ID) {
        switch state {
        case let .progress(currentBytes, totalBytes):
            store.update(with: id, state: .progress(currentBytes: currentBytes, totalBytes: totalBytes))
        case let .success(url):
            log(.info, "Successfully downloaded the media: \(url)")
            store.update(with: id, result: .success(()))
        case let .failed(error):
            log(.error, "The download failed due to the following error: \(error)")
            store.update(with: id, result: .failure(error))
        case .cancelled:
            store.update(with: id, state: .cancelled)
        }
    }
}
