//
//  MediaAssetStorage.swift
//
//
//  Created by Luca Archidiacono on 21.02.2024.
//

import Foundation
import CoreData
import Logger

public final class MediaAssetStorage {
	private let context: NSManagedObjectContext

	public init(persistenceController: PersistenceController) {
		self.context = persistenceController.container.newBackgroundContext()
		self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
	}

	public func load(id: UUID) -> Data? {
		return context.performAndWait {
			let fetchRequest: NSFetchRequest<MediaAssetEntity> = MediaAssetEntity.fetchRequest()
			fetchRequest.fetchLimit = 1
			fetchRequest.predicate = NSPredicate(format: "id == %@", id.uuidString)

			guard let entity = try? fetchRequest.execute().first else { return nil }
			return nil
		}
	}
}
