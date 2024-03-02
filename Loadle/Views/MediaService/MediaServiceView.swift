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
//    @EnvironmentObject private var theme: Theme

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
//		.background(theme.primaryBackgroundColor)
		.onAppear {
			viewModel.fetchAll()
		}
//		.applyTheme(theme)
    }

	var content: some View {
		List {
			ForEach(viewModel.mediaAssetItems) { mediaAssetItem in
				mediaSection(mediaAssetItem: mediaAssetItem)
					.contextMenu {
						ShareLink(item: mediaAssetItem.fileURL.standardizedFileURL)
					}
			}
		}
//        .background(theme.secondaryBackgroundColor)
		.toolbarBackground(.hidden)
        .scrollContentBackground(.hidden)
		.listStyle(.inset)
	}

	func mediaSection(mediaAssetItem: MediaAssetItem) -> some View {
		Section {
			VStack {
				HStack {
					VStack {
						AsyncImageProvider(itemProvider: mediaAssetItem.metadata.iconProvider, placeholder: Image(systemName: "bookmark.fill")) { image in
							image
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: 20, height: 20)
							//							.foregroundStyle(theme.tintColor)
						}
						Spacer()
					}

					VStack {
						Text(mediaAssetItem.metadata.title!)
//						Text(mediaAssetItem.remoteURL.absoluteString)
						Spacer()
					}
//					VStack {
//						AsyncImageProvider(itemProvider: mediaAssetItem.metadata.imageProvider, placeholder: nil) { image in
//							image
//								.resizable()
//								.aspectRatio(contentMode: .fit)
//								.frame(width: 30, height: 30)
//							//							.foregroundStyle(theme.tintColor)
//						}
//					}
				}
			}
		}
		.frame(height: 100)
//		.listRowBackground(theme.primaryBackgroundColor)
	}
}
