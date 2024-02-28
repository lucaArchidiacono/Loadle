//
//  PersistenceController.swift
//
//
//  Created by Luca Archidiacono on 21.02.2024.
//

import Foundation
import CoreData
import Logger

class PMPersistentContainer: NSPersistentContainer {
	public init(name: String, bundle: Bundle = .main) {
		guard let modelURL = Bundle.module.url(forResource: name, withExtension: "momd"),
			  let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
			fatalError("Failed to create momd")
		}

		super.init(name: name, managedObjectModel: managedObjectModel)
	}

	override class func defaultDirectoryURL() -> URL {
		return super.defaultDirectoryURL()
	}
}

public struct PersistenceController {
	public static let shared = PersistenceController()

	let container: PMPersistentContainer

	init(inMemory: Bool = false) {
		self.container = PMPersistentContainer(name: "Loadle")

		setup(inMemory: inMemory)
	}

	private func setup(inMemory: Bool) {
		setupTransformers()
		setupContainer(inMemory: inMemory)
	}

	private func setupTransformers() {
		LPLinkMetadataTransformer.register()
	}

	private func setupContainer(inMemory: Bool) {
		if inMemory {
			self.container.persistentStoreDescriptions.first?.url = URL(filePath: "/dev/null")
		}
		self.container.persistentStoreDescriptions.first?.shouldMigrateStoreAutomatically = true
		self.container.persistentStoreDescriptions.first?.shouldInferMappingModelAutomatically = true

		self.container.viewContext.automaticallyMergesChangesFromParent = true
		self.container.loadPersistentStores { storeDescription, error in
			if let error {
				fatalError("\(error)")
			} else {
				log(.debug, storeDescription.description)
			}
		}
	}
}
