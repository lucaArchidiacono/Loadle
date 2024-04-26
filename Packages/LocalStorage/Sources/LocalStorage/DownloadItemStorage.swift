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

extension Storage {
	public enum DownloadItem {
		static var downloadStorage = ObjectStorage<Models.DownloadItem>(
			storage: SQLiteStorageEngine.default(appendingPath: "DownloadItems")
		)
		public static func write(_ item: Models.DownloadItem) async throws {
			try await downloadStorage.store(item, forKey: CacheKey(item.id.absoluteString))
		}
		public static func delete(_ id: Models.DownloadItem.ID) async throws {
			try await downloadStorage.removeObject(forKey: CacheKey(id.absoluteString))
		}
		public static func search(_ id: Models.DownloadItem.ID) async -> Models.DownloadItem? {
			await downloadStorage.object(forKey: CacheKey(id.absoluteString))
		}
		public static func readAll() async -> [Models.DownloadItem] {
			await downloadStorage.allObjects()
		}
	}
}
