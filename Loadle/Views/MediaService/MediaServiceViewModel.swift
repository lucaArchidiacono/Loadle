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
	enum State {
		case createdArchives
		case selectedSingleMediaAssetItem
		case presentedSearchingViaText
		case dismissedSearchingViaText
		case presentedArchivingSheet
		case dismissedArchivingSheet
		case `default`
	}

	public let mediaService: MediaService
	public var searchText: String = ""
	public var mediaAssetItems: [MediaAssetItem] = []

	private var fetchedMediaAssetItems = [MediaAssetItem]()
	private var filteredMediaAssetItems = [MediaAssetItem]()
	public var selectedMediaAssetItems: Set<MediaAssetItem> = []

	public var archives: [URL] = []

	public var isArchivingSheetPresented: Bool = false
	public var isSearchingPresented: Bool = false

	public var state: State = .default

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
			self.mediaAssetItems = self.fetchedMediaAssetItems
		}
	}

	func search() {
		if searchText.isEmpty {
			mediaAssetItems = fetchedMediaAssetItems
		} else {
			mediaAssetItems = mediaAssetItems.filter { $0.title.lowercased().contains(searchText.lowercased()) }
		}
	}

	func delete(item: MediaAssetItem) {
		Task {
			await MediaAssetService.shared.delete(item)
			fetch()
		}
	}
}
