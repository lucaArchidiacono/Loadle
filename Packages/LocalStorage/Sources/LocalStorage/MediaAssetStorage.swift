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

	public func countMediaAssetsByService() async -> [MediaService: Int] {
		return await context.perform {
			var counts: [MediaService: Int] = [:]

			let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "MediaAssetEntity")
			fetchRequest.resultType = .dictionaryResultType

			// Specify the properties to fetch (service and count)
			let expressionDescription = NSExpressionDescription()
			expressionDescription.name = "count"
			expressionDescription.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "service")])
			expressionDescription.expressionResultType = .integer64AttributeType

			fetchRequest.propertiesToFetch = ["service", expressionDescription]
			fetchRequest.propertiesToGroupBy = ["service"]

			guard let results = try? fetchRequest.execute() else { return [:] }

			for result in results {
				if let serviceString = result["service"] as? String,
				   let service = MediaService(rawValue: serviceString),
				   let count = result["count"] as? Int {
					counts[service] = count
				}
			}

			return counts
		}
	}

	public func searchFor(title: String) async -> [MediaAssetItem] {
		return await context.perform {
			let fetchRequest: NSFetchRequest<MediaAssetEntity> = MediaAssetEntity.fetchRequest()
			fetchRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@", title)

			guard let entities = try? fetchRequest.execute() else { return [] }

			return entities
				.map { entity in
					MediaAssetItem(remoteURL: entity.remoteURL,
								   fileURLs: entity.fileURLs,
								   service: MediaService(rawValue: entity.service)!,
								   artwork: entity.artwork,
								   createdAt: entity.createdAt,
								   title: entity.title)
				}
		}
	}

	public func load(remoteURL: URL) async -> MediaAssetItem? {
		return await context.perform {
			guard let entity = self.getEntity(remoteURL: remoteURL) else { return nil }

			return MediaAssetItem(remoteURL: entity.remoteURL,
								  fileURLs: entity.fileURLs,
								  service: MediaService(rawValue: entity.service)!,
								  artwork: entity.artwork,
								  createdAt: entity.createdAt,
								  title: entity.title)
		}
	}

	public func load(fileURL: URL) async -> MediaAssetItem? {
		return await context.perform {
			guard let entity = self.getEntity(fileURL: fileURL) else { return nil }

			return MediaAssetItem(remoteURL: entity.remoteURL,
								  fileURLs: entity.fileURLs,
								  service: MediaService(rawValue: entity.service)!,
								  artwork: entity.artwork,
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
				MediaAssetItem(remoteURL: entity.remoteURL,
							   fileURLs: entity.fileURLs,
							   service: MediaService(rawValue: entity.service)!,
							   artwork: entity.artwork,
							   createdAt: entity.createdAt,
							   title: entity.title)
			}
		}
	}

	public func delete(_ remoteURL: URL) async {
		return await context.perform {
			guard let entity = self.getEntity(remoteURL: remoteURL) else { return }
			self.context.delete(entity)
			try? self.context.save()
		}
	}

	public func store(mediaAssetItem: MediaAssetItem) async {
		return await context.perform {
			let mediaAssetItemEntity: MediaAssetEntity
			if let entity = self.getEntity(remoteURL: mediaAssetItem.remoteURL) {
				mediaAssetItemEntity = entity
			} else {
				mediaAssetItemEntity = MediaAssetEntity(context: self.context)
			}

			mediaAssetItemEntity.remoteURL = mediaAssetItem.remoteURL
			mediaAssetItemEntity.fileURLs = mediaAssetItem.fileURLs
			mediaAssetItemEntity.service = mediaAssetItem.service.rawValue
			mediaAssetItemEntity.artwork = mediaAssetItem.artwork
			mediaAssetItemEntity.createdAt = mediaAssetItem.createdAt
			mediaAssetItemEntity.title = mediaAssetItem.title

			try? self.context.save()
		}
	}

	private func getEntity(remoteURL: URL) -> MediaAssetEntity? {
		let fetchRequest: NSFetchRequest<MediaAssetEntity> = MediaAssetEntity.fetchRequest()
		fetchRequest.fetchLimit = 1
		fetchRequest.predicate = NSPredicate(format: "remoteURL == %@", remoteURL.absoluteString)

		return try? fetchRequest.execute().first
	}

	private func getEntity(fileURL: URL) -> MediaAssetEntity? {
		let fetchRequest: NSFetchRequest<MediaAssetEntity> = MediaAssetEntity.fetchRequest()
		fetchRequest.fetchLimit = 1
		fetchRequest.predicate = NSPredicate(format: "fileURL == %@", fileURL.absoluteString)

		return try? fetchRequest.execute().first
	}
}
