//
//  DownloadItemEntity+CoreDataProperties.swift
//  Loadle
//
//  Created by Luca Archidiacono on 27.02.2024.
//
//

import Foundation
import CoreData
import LinkPresentation

extension DownloadItemEntity: Identifiable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DownloadItemEntity> {
        return NSFetchRequest<DownloadItemEntity>(entityName: "DownloadItemEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var remoteURL: URL
    @NSManaged public var streamURL: URL
    @NSManaged public var state: Data
    @NSManaged public var metadata: LPLinkMetadata
    @NSManaged public var service: String

}
