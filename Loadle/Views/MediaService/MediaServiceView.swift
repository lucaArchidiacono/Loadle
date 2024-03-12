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
    }

	var content: some View {
		List {
			ForEach(viewModel.mediaAssetItems) { mediaAssetItem in
				MediaAssetItemSectionView(mediaAssetItem: mediaAssetItem)
					.onTapGesture {
						router.covered = .mediaPlayer(fileURL: mediaAssetItem.fileURL)
					}
					.contextMenu {
						ShareLink(item: mediaAssetItem.fileURL.standardizedFileURL)
					}
			}
		}
		.toolbarBackground(.hidden)
        .scrollContentBackground(.hidden)
		.listStyle(.inset)
		.task {
			await viewModel.fetch()
		}
	}
}
