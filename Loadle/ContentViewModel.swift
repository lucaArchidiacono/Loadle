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
	public var searchText: String = ""
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
				_isPresented = !newValue.isEmpty
			}
		}
	}
	public var isPresented: Bool {
		get {
			access(keyPath: \.isPresented)
			return _isPresented
		} set {
			withMutation(keyPath: \.isPresented) {
				_isPresented = newValue
				_selectedMediaAssetItems = newValue ? _selectedMediaAssetItems : []
			}
		}
	}

	private var _selectedMediaAssetItems = Set<MediaAssetItem>()
	private var _isPresented: Bool = false

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
