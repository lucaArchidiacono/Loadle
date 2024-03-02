//
//  MediaServiceViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 28.02.2024.
//

import Foundation
import Models
import Environments

@Observable
@MainActor
final class MediaServiceViewModel {
	var mediaAssetItems = [MediaAssetItem]()
	let mediaService: MediaService

	init(mediaService: MediaService) {
		self.mediaService = mediaService
	}

	func fetchAll() {
		self.mediaAssetItems = MediaAssetService.shared.loadAllAssets(for: mediaService)
	}
}
