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
	public var searchText: String = ""
	public var mediaAssetItems: [MediaAssetItem] {
		if !searchText.isEmpty { return filteredMediaAssetItems }
		else { return fetchedMediaAssetItems }
	}
	private var fetchedMediaAssetItems = [MediaAssetItem]()
	private var filteredMediaAssetItems = [MediaAssetItem]()

	init(mediaService: MediaService) {
		self.mediaService = mediaService
	}

	@ObservationIgnored
	private var fetchTask: Task<Void, Never>?
	public func fetch() {
		if let fetchTask {
			fetchTask.cancel()
		}
		fetchTask = Task { [weak self] in
			guard let self else { return }
			self.fetchedMediaAssetItems = await MediaAssetService.shared.loadAllAssets(for: mediaService)
		}
	}

	func search() {
		if searchText.isEmpty {
			filteredMediaAssetItems = mediaAssetItems
		} else {
			filteredMediaAssetItems = mediaAssetItems.filter { $0.title.lowercased().contains(searchText.lowercased()) }
		}
	}

	func delete(item: MediaAssetItem) {
		Task {
			await MediaAssetService.shared.delete(item)
			fetch()
		}
	}
}
