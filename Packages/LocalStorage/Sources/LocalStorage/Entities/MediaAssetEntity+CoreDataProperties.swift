//
//  MediaAssetEntity+CoreDataProperties.swift
//  Loadle
//
//  Created by Luca Archidiacono on 21.02.2024.
//
//

import Foundation
import CoreData
import LinkPresentation

extension MediaAssetEntity: Identifiable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaAssetEntity> {
        return NSFetchRequest<MediaAssetEntity>(entityName: "MediaAssetEntity")
    }

    @NSManaged var id: UUID
    @NSManaged var remoteURL: URL
    @NSManaged var fileURL: URL
    @NSManaged var service: String
    @NSManaged var metadata: LPLinkMetadata
    @NSManaged var createdAt: Date
}
