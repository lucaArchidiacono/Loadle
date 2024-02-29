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

public final class MediaAssetStorage {
	private let context: NSManagedObjectContext

	init(container: PMPersistentContainer) {
		self.context = container.newBackgroundContext()
		self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
	}

	public func load(id: MediaAssetItem.ID) -> MediaAssetItem? {
		return context.performAndWait {
			guard let entity = getEntity(id: id) else { return nil }

			return MediaAssetItem(id: entity.id,
								  remoteURL: entity.remoteURL,
								  fileURL: entity.fileURL,
								  service: MediaService(rawValue: entity.service)!,
								  metadata: entity.metadata,
								  createdAt: entity.createdAt)
		}
	}

	public func load(fileURL: URL) -> MediaAssetItem? {
		return context.performAndWait {
			guard let entity = getEntity(fileURL: fileURL) else { return nil }

			return MediaAssetItem(id: entity.id,
								  remoteURL: entity.remoteURL,
								  fileURL: entity.fileURL,
								  service: MediaService(rawValue: entity.service)!,
								  metadata: entity.metadata,
								  createdAt: entity.createdAt)
		}
	}

	public func loadAll(using service: MediaService) -> [MediaAssetItem] {
		return context.performAndWait {
			let fetchRequest: NSFetchRequest<MediaAssetEntity> = MediaAssetEntity.fetchRequest()

			fetchRequest.predicate = NSPredicate(format: "service == %@", service.rawValue)
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

			guard let entities = try? fetchRequest.execute() else { return [] }

			return entities.compactMap { entity in
				MediaAssetItem(id: entity.id,
							   remoteURL: entity.remoteURL,
							   fileURL: entity.fileURL,
							   service: MediaService(rawValue: entity.service)!,
							   metadata: entity.metadata,
							   createdAt: entity.createdAt)
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

	public func store(mediaAssetItem: MediaAssetItem) {
		return context.performAndWait {
			let mediaAssetItemEntity: MediaAssetEntity
			if let entity = getEntity(id: mediaAssetItem.id) {
				mediaAssetItemEntity = entity
			} else {
				mediaAssetItemEntity = MediaAssetEntity(context: self.context)
			}

			mediaAssetItemEntity.id = mediaAssetItem.id
			mediaAssetItemEntity.remoteURL = mediaAssetItem.remoteURL
			mediaAssetItemEntity.fileURL = mediaAssetItem.fileURL
			mediaAssetItemEntity.service = mediaAssetItem.service.rawValue
			mediaAssetItemEntity.metadata = mediaAssetItem.metadata
			mediaAssetItemEntity.createdAt = mediaAssetItem.createdAt

			try? context.save()
		}
	}

	private func getEntity(id: MediaAssetItem.ID) -> MediaAssetEntity? {
		let fetchRequest: NSFetchRequest<MediaAssetEntity> = MediaAssetEntity.fetchRequest()
		fetchRequest.fetchLimit = 1
		fetchRequest.predicate = NSPredicate(format: "id == %@", id.uuidString)

		return try? fetchRequest.execute().first
	}

	private func getEntity(fileURL: URL) -> MediaAssetEntity? {
		let fetchRequest: NSFetchRequest<MediaAssetEntity> = MediaAssetEntity.fetchRequest()
		fetchRequest.fetchLimit = 1
		fetchRequest.predicate = NSPredicate(format: "fileURL == %@", fileURL.absoluteString)

		return try? fetchRequest.execute().first
	}
}
