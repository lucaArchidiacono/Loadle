//
//  StorageService.swift
//
//
//  Created by Luca Archidiacono on 16.02.2024.
//

import Foundation
import LocalStorage

public class StorageService {
	public let mediaAssetStorage: MediaAssetStorage = MediaAssetStorage(persistenceController: PersistenceController.shared)
	public let downloadItemStorage: DownloadItemStorage = DownloadItemStorage(persistenceController: PersistenceController.shared)

	public static let shared: StorageService = StorageService()

    private init() {}


}
