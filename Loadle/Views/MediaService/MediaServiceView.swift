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
	@Environment(PlaylistService.self) private var playlistService: PlaylistService

	@State private var viewModel: MediaServiceViewModel

	init(mediaService: MediaService) {
		self._viewModel = .init(wrappedValue: MediaServiceViewModel(mediaService: mediaService))
	}

    var body: some View {
		ZStack {
			content
		}
		.toolbarBackground(.automatic, for: .navigationBar)
		.navigationTitle(viewModel.mediaService.title)
		.onAppear {
			viewModel.fetch()
		}
		.onCompletedDownload {
			viewModel.fetch()
		}
    }

	var content: some View {
		List {
			ForEach(viewModel.mediaAssetItems) { mediaAssetItem in
				MediaAssetItemSectionView(mediaAssetItem: mediaAssetItem) {
						playlistService.select(mediaAssetItem, playlist: viewModel.mediaAssetItems)

						#if 	os(visionOS)
						openWindow(id: "MediaPlayer")
						#else
						router.path.append(.mediaPlayer)
						#endif
				}
				.contextMenu {
					ShareLink(items: mediaAssetItem.fileURLs.map { $0.standardizedFileURL })
				}
			}
		}
		.searchable(text: $viewModel.searchText)
		.onChange(of: viewModel.searchText, initial: false) {
			viewModel.search()
		}
		.toolbarBackground(.hidden)
        .scrollContentBackground(.hidden)
		.listStyle(.inset)
	}
}
