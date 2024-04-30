//
//  MediaAssetService.swift
//
//
//  Created by Luca Archidiacono on 28.02.2024.
//

import Foundation
import LocalStorage
import Logger
import Models
import UniformTypeIdentifiers

public final class MediaAssetService {
    public static let shared = MediaAssetService()

    public func store(downloadItem: DownloadItem, originalFileURL: URL) async {
        do {
            log(.info, "Storing new `DownloadItem` as `MediaAsset`: \(downloadItem)")
            let serviceURL = try Self.loadBaseURL(service: downloadItem.service)
            let fileURL = serviceURL.appendingPathComponent(originalFileURL.lastPathComponent, conformingTo: .fileURL)
            var fileURLString = fileURL.absoluteString
            guard let serviceURLRange = fileURLString.range(of: serviceURL.absoluteString) else {
                log(.error, "Was not able to build a relative URL which points to: \(fileURL)")
                return
            }
            fileURLString.removeSubrange(serviceURLRange)

            guard let relativeFileURL = URL(string: fileURLString) else {
                log(.error, "Was not able to build a relative URL using: \(fileURLString)")
                return
            }

            let existingMediaAsset = await Storage.MediaAssetItem.search(remoteURL: downloadItem.remoteURL)

            if let existingMediaAsset {
                if FileManager.default.fileExists(atPath: fileURL.standardizedFileURL.path(percentEncoded: false)) {
                    log(.warning, "File already exists. Will replace at: \(fileURL) with item at: \(originalFileURL)")
                    try FileManager.default.removeItem(at: fileURL)
                    try FileManager.default.moveItem(at: originalFileURL, to: fileURL)
                } else {
                    log(.info, "File does not exist yet. Will move at: \(originalFileURL) to: \(fileURL)")
                    try FileManager.default.moveItem(at: originalFileURL, to: fileURL)

                    let newFileURLs = existingMediaAsset.fileURLs + [relativeFileURL]
                    let newMediaAsset = existingMediaAsset.configure(fileURLs: newFileURLs)

                    try await Storage.MediaAssetItem.write(newMediaAsset)
                    log(.info, "Successfully stored \(newMediaAsset) into CoreData DB.")
                }
            } else {
                log(.info, "File does not exist yet. Will move at: \(originalFileURL) to: \(fileURL)")
                try FileManager.default.moveItem(at: originalFileURL, to: fileURL)
                let artwork = try? await downloadItem.metadata.imageProvider?.loadItem(forTypeIdentifier: UTType.image.identifier) as? Data
                let title = downloadItem.metadata.title!

                let newMediaAsset = MediaAssetItem(
                    remoteURL: downloadItem.remoteURL,
                    fileURLs: [relativeFileURL],
                    service: downloadItem.service,
                    artwork: artwork,
                    createdAt: .now,
                    title: title
                )

                try await Storage.MediaAssetItem.write(newMediaAsset)
                log(.info, "Successfully stored \(newMediaAsset) into CoreData DB.")
            }

            try? FileManager.default.removeItem(at: originalFileURL)

        } catch {
            log(.error, error)
        }
    }

    public func loadCountIndex() async -> [MediaService: Int] {
        await Storage.MediaAssetItem.countMediaAssetsByService()
    }

    public func loadAllAssets(for service: MediaService) async -> [MediaAssetItem] {
        await Storage.MediaAssetItem.readAll(using: service)
            .compactMap(Self.transform(_:))
            .sorted(by: { $0.title < $1.title })
    }

    public func searchFor(title: String) async -> [MediaAssetItem] {
        await Storage.MediaAssetItem.searchFor(title: title)
            .compactMap(Self.transform(_:))
    }

    public func delete(_ item: MediaAssetItem) async {
        guard let item = Self.transform(item) else {
            log(.warning, "Was not able to transform MediaAssetItem.")
            return
        }
        do {
            for fileURL in item.fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
            try await Storage.MediaAssetItem.delete(item.id)
        } catch {
            log(.error, error)
        }
    }

    private static func transform(_ data: MediaAssetItem) -> MediaAssetItem? {
        guard let serviceURL = try? loadBaseURL(service: data.service) else { return nil }
        let newFileURLs = data
            .fileURLs
            .map { URL(filePath: $0.path, directoryHint: .notDirectory, relativeTo: serviceURL) }
        return data.configure(fileURLs: newFileURLs)
    }

    private static func loadBaseURL(service: MediaService) throws -> URL {
        let downloadsURL = try FileManager.default
            .url(for: .documentDirectory,
                 in: .userDomainMask,
                 appropriateFor: .documentsDirectory,
                 create: true)
            .appendingPathComponent("DOWNLOADS", conformingTo: .directory)
            .appendingPathComponent(service.rawValue.capitalized, conformingTo: .directory)

        if !FileManager.default.fileExists(atPath: downloadsURL.standardizedFileURL.path(percentEncoded: false)) {
            try FileManager.default.createDirectory(at: downloadsURL, withIntermediateDirectories: true, attributes: nil)
        }

        return downloadsURL
    }
}
