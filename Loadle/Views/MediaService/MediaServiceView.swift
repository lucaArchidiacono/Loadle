//
//  MediaServiceView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Environments
import Foundation
import Models
import SwiftUI
import Fundamentals

struct MediaServiceView: View {
	@Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var preferences: UserPreferences

    @Environment(Router.self) private var router: Router

	@State private var viewModel: MediaServiceViewModel

	init(mediaService: MediaService) {
		self._viewModel = .init(wrappedValue: MediaServiceViewModel(mediaService: mediaService))
	}

    var body: some View {
		ZStack {
			content
		}
		.navigationTitle(viewModel.mediaService.title)
		.onAppear {
			viewModel.fetch()
		}
		.onChange(of: viewModel.searchText, initial: false) {
			viewModel.search()
		}
    }

	var content: some View {
		List {
			ForEach(viewModel.searchText.isEmpty ? viewModel.mediaAssetItems : viewModel.filteredMediaAssetItems ) { mediaAssetItem in
				MediaAssetItemSectionView(mediaAssetItem: mediaAssetItem) {
					#if os(visionOS)
					openWindow(value: mediaAssetItem.fileURL)
					#else
					router.covered = .mediaPlayer(fileURL: mediaAssetItem.fileURL)
					#endif
				}
				.contextMenu {
					ShareLink(item: mediaAssetItem.fileURL.standardizedFileURL)
				}
			}
		}
		.searchable(text: $viewModel.searchText)
		.toolbarBackground(.hidden)
        .scrollContentBackground(.hidden)
		.listStyle(.inset)
	}
}
