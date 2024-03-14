//
//  MediaAssetService.swift
//
//
//  Created by Luca Archidiacono on 28.02.2024.
//

import Foundation
import Models
import Logger
import LocalStorage

public final class MediaAssetService {
	public static let shared = MediaAssetService()

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

			if FileManager.default.fileExists(atPath: fileURL.standardizedFileURL.path(percentEncoded: false)),
			   await PersistenceController.shared.mediaAsset.load(fileURL: relativeFileURL) != nil {
				log(.warning, "File already exists. Will replace at: \(fileURL) with item at: \(originalFileURL)")
				try FileManager.default.removeItem(at: fileURL)
				try FileManager.default.moveItem(at: originalFileURL, to: fileURL)
			} else {
				log(.info, "File does not exist yet. Will move at: \(originalFileURL) to: \(fileURL)")
				try FileManager.default.moveItem(at: originalFileURL, to: fileURL)

				let mediaAssetItem = MediaAssetItem(
					id: UUID(),
					remoteURL: downloadItem.remoteURL,
					fileURL: relativeFileURL,
					service: downloadItem.service,
					metadata: downloadItem.metadata,
					createdAt: .now,
					title: downloadItem.metadata.title!)

				await PersistenceController.shared.mediaAsset.store(mediaAssetItem: mediaAssetItem)
				log(.info, "Successfully stored \(mediaAssetItem) into CoreData DB.")
			}

			try? FileManager.default.removeItem(at: originalFileURL)

		} catch {
			log(.error, error)
		}
	}

	public func loadAllAssets(for service: MediaService) async -> [MediaAssetItem] {
		await PersistenceController.shared.mediaAsset
			.loadAll(using: service)
			.compactMap { mediaAssetItem -> MediaAssetItem? in
				let urlString = mediaAssetItem.fileURL.path
				guard let serviceURL = try? Self.loadBaseURL(service: mediaAssetItem.service) else { return nil }
				let newFileURL = URL(filePath: urlString, directoryHint: .notDirectory, relativeTo: serviceURL)
				return mediaAssetItem.configure(fileURL: newFileURL)
			}
	}
}
