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

	func fetchMediaAssetIndex() {
		Task {
			mediaAssetItemIndex = await MediaAssetService.shared.loadCountIndex()
		}
	}

	@ObservationIgnored
	private var searchTask: Task<Void, Never>?
	func search() {
		if let searchTask {
			searchTask.cancel()
		}

		searchTask = Task {
			filteredMediaAssetItems = await MediaAssetService.shared.searchFor(title: searchText)
		}
	}
}
