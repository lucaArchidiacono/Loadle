//
//  DownloadItemStorage.swift
//  
//
//  Created by Luca Archidiacono on 27.02.2024.
//

import Foundation
import Models
import CoreData
import Bodega
import Fundamentals
import Logger

extension Storage {
	public enum DownloadItem {
		static let path = "DownloadItems"
		static var downloadStorage = ObjectStorage<Models.DownloadItem>(
			storage: SQLiteStorageEngine.default(appendingPath: path)
		)
		public static func write(_ item: Models.DownloadItem) async throws {
			log(.info, "🏁 Start writing to locale storage \(path) using item: \(item)")
			try await downloadStorage.store(item, forKey: CacheKey(item.id.absoluteString))
			log(.info, "✅ Finished writing to locale storage \(path)")
		}
		public static func delete(_ id: Models.DownloadItem.ID) async throws {
			log(.info, "🏁 Start deleting in locale storage \(path) using DownloadItem.ID: \(id)")
			try await downloadStorage.removeObject(forKey: CacheKey(id.absoluteString))
			log(.info, "✅ Finished deleting in locale storage \(path)")
		}
		public static func search(_ id: Models.DownloadItem.ID) async -> Models.DownloadItem? {
			log(.info, "🏁 Start searching in locale storage \(path) using DownloadItem.ID: \(id)")
			let result = await downloadStorage.object(forKey: CacheKey(id.absoluteString))
			log(.info, "✅ Finished searching in locale storage \(path) with result: \(String(describing: result))")
			return result
		}
		public static func readAll() async -> [Models.DownloadItem] {
			log(.info, "🏁 Start fetching all DownloadItem in locale storage \(path)")
			let result = await downloadStorage.allObjects()
			log(.info, "✅ Finished fetching in locale storage \(path) with result: \(result)")
			return result
		}
	}
}
