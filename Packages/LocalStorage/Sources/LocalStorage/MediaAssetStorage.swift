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

	public func searchFor(title: String) async -> [MediaAssetItem] {
		return await context.perform {
			let fetchRequest: NSFetchRequest<MediaAssetEntity> = MediaAssetEntity.fetchRequest()
			fetchRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@", title)

			guard let entities = try? fetchRequest.execute() else { return [] }

			return entities
				.map { entity in
					MediaAssetItem(id: entity.id,
								   remoteURL: entity.remoteURL,
								   fileURL: entity.fileURL,
								   service: MediaService(rawValue: entity.service)!,
								   metadata: entity.metadata,
								   createdAt: entity.createdAt,
								   title: entity.title)
				}
		}
	}

	public func load(id: MediaAssetItem.ID) async -> MediaAssetItem? {
		return await context.perform {
			guard let entity = self.getEntity(id: id) else { return nil }

			return MediaAssetItem(id: entity.id,
								  remoteURL: entity.remoteURL,
								  fileURL: entity.fileURL,
								  service: MediaService(rawValue: entity.service)!,
								  metadata: entity.metadata,
								  createdAt: entity.createdAt,
								  title: entity.title)
		}
	}

	public func load(fileURL: URL) async -> MediaAssetItem? {
		return await context.perform {
			guard let entity = self.getEntity(fileURL: fileURL) else { return nil }

			return MediaAssetItem(id: entity.id,
								  remoteURL: entity.remoteURL,
								  fileURL: entity.fileURL,
								  service: MediaService(rawValue: entity.service)!,
								  metadata: entity.metadata,
								  createdAt: entity.createdAt,
								  title: entity.title)
		}
	}

	public func loadAll(using service: MediaService) async -> [MediaAssetItem] {
		return await context.perform {
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
							   createdAt: entity.createdAt,
							   title: entity.title)
			}
		}
	}

	public func delete(_ id: MediaAssetItem.ID) async {
		return await context.perform {
			guard let entity = self.getEntity(id: id) else { return }
			self.context.delete(entity)
			try? self.context.save()
		}
	}

	public func store(mediaAssetItem: MediaAssetItem) async {
		return await context.perform {
			let mediaAssetItemEntity: MediaAssetEntity
			if let entity = self.getEntity(id: mediaAssetItem.id) {
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
			mediaAssetItemEntity.title = mediaAssetItem.title

			try? self.context.save()
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
