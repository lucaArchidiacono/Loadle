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
    @EnvironmentObject private var theme: Theme

    @Environment(MediaAssetService.self) private var service: MediaAssetService
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
		.background(theme.primaryBackgroundColor)
		.onAppear {
			viewModel.fetchAll(service: service)
		}
		.applyTheme(theme)
    }

	var content: some View {
		List {
			ForEach(viewModel.mediaAssetItems) { mediaAssetItem in
				mediaSection(mediaAssetItem: mediaAssetItem)
			}
		}
        .background(theme.secondaryBackgroundColor)
		.toolbarBackground(.hidden)
        .scrollContentBackground(.hidden)
	}

	func mediaSection(mediaAssetItem: MediaAssetItem) -> some View {
		Section {
			VStack {
				HStack {
					AsyncImageProvider(itemProvider: mediaAssetItem.metadata.iconProvider, placeholder: Image(systemName: "bookmark.fill")) { image in
						image
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 10, height: 10)
							.foregroundStyle(theme.tintColor)
					}
					Text(mediaAssetItem.metadata.title ?? mediaAssetItem.remoteURL.absoluteString)

					AsyncImageProvider(itemProvider: mediaAssetItem.metadata.imageProvider, placeholder: nil) { image in
						image
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 30, height: 30)
							.foregroundStyle(theme.tintColor)
					}
				}
			}
		}
		.listRowBackground(theme.primaryBackgroundColor)
	}
}
