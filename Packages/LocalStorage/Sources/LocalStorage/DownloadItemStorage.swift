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

	public func load(id: DownloadItem.ID) -> DownloadItem? {
		return context.performAndWait {
			guard let entity = getEntity(id: id) else { return nil }

			return DownloadItem(id: entity.id,
								remoteURL: entity.remoteURL,
								streamURL: entity.streamURL,
								service: MediaService(rawValue: entity.service)!,
								state: try! JSONDecoder().decode(DownloadItem.State.self, from: entity.state),
								metadata: entity.metadata)
		}
	}

	public func loadAll() -> [DownloadItem] {
		return context.performAndWait {
			let fetchRequest: NSFetchRequest<DownloadItemEntity> = DownloadItemEntity.fetchRequest()

			guard let entities = try? fetchRequest.execute() else { return [] }

			return entities.compactMap { entity in
				DownloadItem(id: entity.id,
								remoteURL: entity.remoteURL,
								streamURL: entity.streamURL,
								service: MediaService(rawValue: entity.service)!,
								state: try! JSONDecoder().decode(DownloadItem.State.self, from: entity.state),
								metadata: entity.metadata)
			}
		}
	}

	public func delete(_ id: DownloadItem.ID) {
		return context.performAndWait {
			guard let entity = getEntity(id: id) else { return }
			context.delete(entity)
			try? context.save()
		}
	}

	public func store(downloadItem: DownloadItem) {
		return context.performAndWait {
			let downloadItemEntity: DownloadItemEntity
			if let entity = getEntity(id: downloadItem.id) {
				downloadItemEntity = entity
			} else {
				downloadItemEntity = DownloadItemEntity(context: self.context)
			}

			downloadItemEntity.id = downloadItem.id
			downloadItemEntity.metadata = downloadItem.metadata
			downloadItemEntity.remoteURL = downloadItem.remoteURL
			downloadItemEntity.streamURL = downloadItem.streamURL
			downloadItemEntity.service = downloadItem.service.rawValue
			downloadItemEntity.state = try! JSONEncoder().encode(downloadItem.state)

			try? context.save()
		}
	}

	private func getEntity(id: DownloadItem.ID) -> DownloadItemEntity? {
		let fetchRequest: NSFetchRequest<DownloadItemEntity> = DownloadItemEntity.fetchRequest()
		fetchRequest.fetchLimit = 1
		fetchRequest.predicate = NSPredicate(format: "id == %@", id.uuidString)

		return try? fetchRequest.execute().first
	}
}
