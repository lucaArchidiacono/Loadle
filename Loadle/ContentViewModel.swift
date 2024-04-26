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
		case searchingViaText
		case `default`
	}

	public var searchText: String = ""
	public var isSearchingPresented: Bool = false
	public var filteredMediaAssetItems: [MediaAssetItem] = []
	public var mediaAssetItemIndex: [MediaService: Int] = [:]

	public var archives: [URL] = []
	public var selectedMediaAssetItems: Set<MediaAssetItem> {
		get {
			access(keyPath: \.selectedMediaAssetItems)
			return _selectedMediaAssetItems
		}
		set {
			withMutation(keyPath: \.selectedMediaAssetItems) {
				_selectedMediaAssetItems = newValue
				_isArchivingSheetPresented = !newValue.isEmpty
			}
		}
	}
	public var isArchivingSheetPresented: Bool {
		get {
			access(keyPath: \.isArchivingSheetPresented)
			return _isArchivingSheetPresented
		} set {
			withMutation(keyPath: \.isArchivingSheetPresented) {
				_isArchivingSheetPresented = newValue
				_selectedMediaAssetItems = newValue ? _selectedMediaAssetItems : []
			}
		}
	}
	public var state: State = .default

	private var _selectedMediaAssetItems = Set<MediaAssetItem>()
	private var _isArchivingSheetPresented: Bool = false

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
