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
				mediaSection(mediaAssetItem: mediaAssetItem)
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
						}
						Spacer()
					}

					VStack {
						Text(mediaAssetItem.metadata.title!)
						Spacer()
					}
				}
                Text(mediaAssetItem.remoteURL.absoluteString)
			}
		}
		.frame(height: 100)
        .onTapGesture {
            router.path.append(.mediaPlayer(fileURL: mediaAssetItem.fileURL))
        }
	}
}
