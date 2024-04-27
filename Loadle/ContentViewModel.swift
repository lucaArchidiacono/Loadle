//
//  ContentViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 14.03.2024.
//

import Foundation
import LocalStorage
import Environments
import Models

@MainActor
@Observable
final class ContentViewModel {
	enum State {
		case createdArchives
		case selectedSingleMediaAssetItem
		case presentedSearchingViaText
		case dismissedSearchingViaText
		case presentedArchivingSheet
		case dismissedArchivingSheet
		case `default`
	}

	public var searchText: String = ""
	public var filteredMediaAssetItems: [MediaAssetItem] = []
	public var mediaAssetItemIndex: [MediaService: Int] = [:]
	public var selectedMediaAssetItems: Set<MediaAssetItem> = []

	public var archives: [URL] = []
	
	public var isArchivingSheetPresented: Bool = false
	public var isSearchingPresented: Bool = false
	
	public var state: State = .default

	@ObservationIgnored
	private var fetchIndexTask: Task<Void, Never>?
	func fetchMediaAssetIndex() {
		if let fetchIndexTask {
			fetchIndexTask.cancel()
		}

		fetchIndexTask = Task { [weak self] in
			guard let self else { return }
			self.mediaAssetItemIndex = await MediaAssetService.shared.loadCountIndex()
		}
	}

	@ObservationIgnored
	private var searchTask: Task<Void, Never>?
	func search() {
		if let searchTask {
			searchTask.cancel()
		}

		searchTask = Task { [weak self] in
			guard let self else { return }
			self.filteredMediaAssetItems = await MediaAssetService.shared.searchFor(title: searchText)
		}
	}
}
