//
//  ContentViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 14.03.2024.
//

import Foundation
import LocalStorage
import Models

@MainActor
@Observable
final class ContentViewModel {
	var mediaAssetsCount: [MediaService: Int] = [:]

	func fetchAll() {
		Task {
			mediaAssetsCount = await PersistenceController.shared.mediaAsset.countMediaAssetsByService()
		}
	}
}
