//
//  MediaServiceViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 28.02.2024.
//

import Foundation
import Models
import Environments
import AVFoundation
import Logger

@Observable
@MainActor
final class MediaServiceViewModel {
	public let mediaService: MediaService
	public var mediaAssetItems = [MediaAssetItem]()
	public var filteredMediaAssetItems = [MediaAssetItem]()
	public var searchText: String = ""

	init(mediaService: MediaService) {
		self.mediaService = mediaService
	}

	public func fetch() {
		Task {
			self.mediaAssetItems = await MediaAssetService.shared.loadAllAssets(for: mediaService)
		}
	}

	func search() {
		if searchText.isEmpty {
			filteredMediaAssetItems = mediaAssetItems
		} else {
			filteredMediaAssetItems = mediaAssetItems.filter { $0.title.lowercased().contains(searchText.lowercased()) }
		}
	}
}
