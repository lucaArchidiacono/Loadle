//
//  MediaAssetStorage.swift
//
//
//  Created by Luca Archidiacono on 21.02.2024.
//

import Foundation
import CoreData
import Models
import Logger
import Bodega

extension Storage {
	public enum MediaAssetItem {
		static var mediaAssetStorage = ObjectStorage<Models.MediaAssetItem>(
			storage: SQLiteStorageEngine.default(appendingPath: "MediaAssets")
		)
		public static func write(_ item: Models.MediaAssetItem) async throws {
			try await mediaAssetStorage.store(item, forKey: CacheKey(item.id.absoluteString))
		}
		public static func delete(_ id: Models.MediaAssetItem.ID) async throws {
			try await mediaAssetStorage.removeObject(forKey: CacheKey(id.absoluteString))
		}
		public static func search(_ id: Models.MediaAssetItem.ID) async -> Models.MediaAssetItem? {
			await mediaAssetStorage.object(forKey: CacheKey(id.absoluteString))
		}
		public static func search(remoteURL: URL) async -> Models.MediaAssetItem? {
			await readAll()
				.first(where: { $0.remoteURL.absoluteString == remoteURL.absoluteString })
		}
		public static func search(fileURL: URL) async -> Models.MediaAssetItem? {
			await readAll()
				.first(where: { $0.fileURLs.contains(where: { $0.absoluteString == fileURL.absoluteString }) })
		}
		public static func readAll(using service: Models.MediaService) async -> [Models.MediaAssetItem] {
			await readAll()
				.filter { $0.service == service }
		}
		public static func readAll() async -> [Models.MediaAssetItem] {
			await mediaAssetStorage.allObjects()
		}

		// Utilities
		public static func countMediaAssetsByService() async -> [MediaService: Int] {
			return await readAll()
				.reduce(into: [MediaService: Int]()) { partialResult, item in
					partialResult[item.service, default: 0] += 1
				}
		}
		public static func searchFor(title: String) async -> [Models.MediaAssetItem] {
			return await readAll()
				.filter { $0.title.lowercased().contains(title.lowercased()) }
		}
	}
}
