//
//  DownloadItemStorage.swift
//  
//
//  Created by Luca Archidiacono on 27.02.2024.
//

import Foundation
import Models
import CoreData

public final class DownloadItemStorage {
	private let context: NSManagedObjectContext

	init(container: PMPersistentContainer) {
		self.context = container.newBackgroundContext()
		self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
	}

	public func load(_ url: URL) async -> DownloadItem? {
		return await context.perform {
			guard let entity = self.getEntity(url: url) else { return nil }

			return DownloadItem(remoteURL: entity.remoteURL,
								streamURL: entity.streamURL,
								service: MediaService(rawValue: entity.service)!,
								state: try! JSONDecoder().decode(DownloadItem.State.self, from: entity.state),
								metadata: entity.metadata)
		}
	}

	public func loadAll() async -> [DownloadItem] {
		return await context.perform {
			let fetchRequest: NSFetchRequest<DownloadItemEntity> = DownloadItemEntity.fetchRequest()

			guard let entities = try? fetchRequest.execute() else { return [] }

			return entities.compactMap { entity in
				DownloadItem(remoteURL: entity.remoteURL,
							 streamURL: entity.streamURL,
							 service: MediaService(rawValue: entity.service)!,
							 state: try! JSONDecoder().decode(DownloadItem.State.self, from: entity.state),
							 metadata: entity.metadata)
			}
		}
	}

	public func delete(_ url: URL) async {
		return await context.perform {
			guard let entity = self.getEntity(url: url) else { return }
			self.context.delete(entity)
			try? self.context.save()
		}
	}

	public func store(downloadItem: DownloadItem) async {
		return await context.perform {
			let downloadItemEntity: DownloadItemEntity
			if let entity = self.getEntity(url: downloadItem.streamURL) {
				downloadItemEntity = entity
			} else {
				downloadItemEntity = DownloadItemEntity(context: self.context)
			}

			downloadItemEntity.metadata = downloadItem.metadata
			downloadItemEntity.remoteURL = downloadItem.remoteURL
			downloadItemEntity.streamURL = downloadItem.streamURL
			downloadItemEntity.service = downloadItem.service.rawValue
			downloadItemEntity.state = try! JSONEncoder().encode(downloadItem.state)

			try? self.context.save()
		}
	}

	private func getEntity(url: URL) -> DownloadItemEntity? {
		let fetchRequest: NSFetchRequest<DownloadItemEntity> = DownloadItemEntity.fetchRequest()
		fetchRequest.fetchLimit = 1
		fetchRequest.predicate = NSPredicate(format: "streamURL == %@", url.absoluteString)

		return try? fetchRequest.execute().first
	}
}
