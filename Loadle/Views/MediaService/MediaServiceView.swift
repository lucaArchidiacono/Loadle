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
import BottomSheet

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
					viewModel.selectedMediaAssetItems = [mediaAssetItem]
					viewModel.state = .selectedSingleMediaAssetItem
//						playlistService.select(mediaAssetItem, playlist: viewModel.mediaAssetItems)
//
//						#if 	os(visionOS)
//						openWindow(id: "MediaPlayer")
//						#else
//						router.path.append(.mediaPlayer)
//						#endif
				}
				.swipeActions(edge: .trailing) {
					Button(role: .destructive,
						   action: { viewModel.delete(item: mediaAssetItem) },
						   label: { Image(systemName: "trash") })
				}
				.contextMenu {
					ShareLink(items: mediaAssetItem.fileURLs.map { $0.standardizedFileURL })
				}
			}
		}
		.searchable(
			text: $viewModel.searchText,
			isPresented: .init(
				get: { viewModel.isSearchingPresented },
				set: { newValue in
					viewModel.isSearchingPresented = newValue

					if newValue {
						viewModel.state = .presentedSearchingViaText
					} else {
						viewModel.state = .dismissedSearchingViaText
					}
				}
			)
		)
		.onChange(of: viewModel.searchText, initial: false) {
			viewModel.search()
		}
		.toolbarBackground(.hidden)
        .scrollContentBackground(.hidden)
		.listStyle(.inset)
		.bottomSheet(
			isPresented: .init(
				get: { viewModel.isArchivingSheetPresented },
				set: { newValue in
					viewModel.isArchivingSheetPresented = newValue

					if newValue {
						viewModel.state = .presentedArchivingSheet
					} else {
						viewModel.state = .dismissedArchivingSheet
					}
				}
			),
			detents: [.fixed(100), .medium, .ratio(0.75)],
			shouldScrollExpandSheet: true,
			largestUndimmedDetent: nil,
			showGrabber: true,
			cornerRadius: 20,
			dismissable: true
		) {
			MediaAssetItemsArchiveList(selectedMediaAssetItems: viewModel.selectedMediaAssetItems) { archives in
				self.viewModel.archives = archives
				self.viewModel.state = .createdArchives
			}
		}
		.onChange(of: viewModel.state) { (oldValue, newValue) in
			switch newValue {
			case .default:
				break
			case .selectedSingleMediaAssetItem:
				viewModel.isArchivingSheetPresented = true
			case .presentedArchivingSheet:
				break
			case .dismissedArchivingSheet:
				break
			case .createdArchives:
				self.viewModel.isArchivingSheetPresented = false

				Task {
					try? await Task.sleep(for: .milliseconds(1))

					let activityController = UIActivityViewController(activityItems: viewModel.archives, applicationActivities: nil)
					UIApplication.shared
						.connectedScenes
						.compactMap { $0 as? UIWindowScene }
						.first?
						.keyWindow?
						.rootViewController?
						.present(activityController, animated: true)
				}
			case .presentedSearchingViaText:
				break
			case .dismissedSearchingViaText:
				break
			}
		}
	}
}
