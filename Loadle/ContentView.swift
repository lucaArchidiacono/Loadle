//
//  ContentView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import Environments
import Generator
import Logger
import Models
import SwiftUI

struct ContentView: View {
	@Environment(\.scenePhase) var scenePhase
    @Environment(\.openWindow) private var openWindow
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @EnvironmentObject private var preferences: UserPreferences

    @State private var selectedDestination: Destination? = nil
	@State private var viewModel: ContentViewModel = ContentViewModel()

    @Binding var router: Router
	@Binding var currentSize: CGSize

    var body: some View {
		GeometryReader { geometry in
			sidebarView
				.onAppear {
					currentSize = geometry.size
				}
				.onChange(of: geometry.size) { oldValue, newValue in
					currentSize = newValue
				}
		}
    }

    @ViewBuilder
    var sidebarView: some View {
        NavigationSplitView {
			if !viewModel.searchText.isEmpty {
				mediaAssetItemSearchList
			} else {
				mediaServiceList
			}
        } detail: {
            if let selectedDestination {
                switch selectedDestination {
                case let .media(mediaService):
                    MediaServiceDestination(mediaService: mediaService)
                        .id(Destination.media(service: mediaService))
                }
            } else {
                EmptyView()
            }
        }
		.searchable(text: $viewModel.searchText)
		.onChange(of: viewModel.searchText, initial: false) {
			viewModel.search()
		}
    }

	@ViewBuilder
	var mediaAssetItemSearchList: some View {
		List {
			ForEach(viewModel.filteredMediaAssetItems) { mediaAssetItem in
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
		.toolbarBackground(.hidden)
		.scrollContentBackground(.hidden)
		.listStyle(.inset)
		.withPath()
		.withSheetDestinations(destination: $router.presented)
		.withCoverDestinations(destination: $router.covered)
	}

	@ViewBuilder
	var mediaServiceList: some View {
		List(selection: $selectedDestination) {
			servicesSection
		}
		.listStyle(.insetGrouped)
		.scrollContentBackground(.hidden)
		.navigationTitle(L10n.appTitle)
		.toolbar {
			SettingsToolbar(placement: .topBarLeading) {
				router.presented = .settings
			}
			AddToolbar(placement: .topBarTrailing) {
				#if os(visionOS)
				openWindow(id: "Download")
				#else
				router.presented = .download
				#endif
			}
		}
		.withPath()
		.withSheetDestinations(destination: $router.presented, onDismiss: {
			viewModel.fetchAll()
		})
		.withCoverDestinations(destination: $router.covered) {
			viewModel.fetchAll()
		}
	}

    @ViewBuilder
    var servicesSection: some View {
        Section(L10n.mediaServicesTitle) {
            ForEach(MediaService.allCases) { service in
                NavigationLink(value: Destination.media(service: service)) {
					service.label(count: viewModel.mediaAssetItemIndex[service])
                }
            }
        }
		.onAppear {
			viewModel.fetchAll()
		}
    }
}

#Preview {
	ContentView(router: .constant(Router()), currentSize: .constant(.zero))
        .environmentObject(UserPreferences.shared)
}
