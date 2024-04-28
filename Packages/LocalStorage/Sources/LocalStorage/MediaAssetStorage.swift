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
		static let path = "MediaAssets"
		static var mediaAssetStorage = ObjectStorage<Models.MediaAssetItem>(
			storage: SQLiteStorageEngine.default(appendingPath: path)
		)
		public static func write(_ item: Models.MediaAssetItem) async throws {
			log(.info, "🏁 Start writing to locale storage \(path) using item: \(item)")
			try await mediaAssetStorage.store(item, forKey: CacheKey(item.id.absoluteString))
			log(.info, "✅ Finished writing to locale storage \(path)")
		}
		public static func delete(_ id: Models.MediaAssetItem.ID) async throws {
			log(.info, "🏁 Start deleting in locale storage \(path) using MediaAssetItem.ID: \(id)")
			try await mediaAssetStorage.removeObject(forKey: CacheKey(id.absoluteString))
			log(.info, "✅ Finished deleting in locale storage \(path)")
		}
		public static func search(_ id: Models.MediaAssetItem.ID) async -> Models.MediaAssetItem? {
			log(.info, "🏁 Start searching in locale storage \(path) using MediaAssetItem.ID: \(id)")
			let result = await mediaAssetStorage.object(forKey: CacheKey(id.absoluteString))
			log(.info, "✅ Finished searching in locale storage \(path) with result: \(String(describing: result))")
			return result
		}
		public static func search(remoteURL: URL) async -> Models.MediaAssetItem? {
			log(.info, "🏁 Start searching in locale storage \(path) using remoteURL: \(remoteURL)")
			let result = await readAll()
				.first(where: { $0.remoteURL.absoluteString == remoteURL.absoluteString })
			log(.info, "✅ Finished searching in locale storage \(path) with result: \(String(describing: result))")
			return result
		}
		public static func search(fileURL: URL) async -> Models.MediaAssetItem? {
			log(.info, "🏁 Start searching in locale storage \(path) using fileURL: \(fileURL)")
			let result = await readAll()
				.first(where: { $0.fileURLs.contains(where: { $0.absoluteString == fileURL.absoluteString }) })
			log(.info, "✅ Finished searching in locale storage \(path) with result: \(String(describing: result))")
			return result
		}
		public static func readAll(using service: Models.MediaService) async -> [Models.MediaAssetItem] {
			log(.info, "🏁 Start fetching all MediaAssetItem in locale storage \(path)")
			let result = await readAll()
				.filter { $0.service == service }
			log(.info, "✅ Finished fetching in locale storage \(path) with result: \(result)")
			return result
		}
		public static func readAll() async -> [Models.MediaAssetItem] {
			log(.info, "🏁 Start fetching all MediaAssetItem in locale storage \(path)")
			let result = await mediaAssetStorage.allObjects()
			log(.info, "✅ Finished fetching in locale storage \(path) with result: \(result)")
			return result
		}

		// Utilities
		public static func countMediaAssetsByService() async -> [MediaService: Int] {
			log(.info, "🏁 Start fetching MediaService count in locale storage \(path)")
			let result = await readAll()
				.reduce(into: [MediaService: Int]()) { partialResult, item in
					partialResult[item.service, default: 0] += 1
				}
			log(.info, "✅ Finished fetching in locale storage \(path) with result: \(result)")
			return result
		}
		public static func searchFor(title: String) async -> [Models.MediaAssetItem] {
			log(.info, "🏁 Start searching in locale storage \(path) using title: \(title)")
			let result = await readAll()
				.filter { $0.title.lowercased().contains(title.lowercased()) }
			log(.info, "✅ Finished fetching in locale storage \(path) with result: \(result)")
			return result
		}
	}
}
