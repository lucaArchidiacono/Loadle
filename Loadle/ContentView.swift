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
	@Environment(\.colorScheme) var colorScheme
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
			Group {
				if !viewModel.searchText.isEmpty {
					searchList
				} else {
					defaultList
				}
			}
			.withPath()
			.withSheetDestinations(destination: $router.presented)
			.withCoverDestinations(destination: $router.covered)
			.searchable(text: $viewModel.searchText)
			.onChange(of: viewModel.searchText, initial: false) {
				viewModel.search()
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
    }

	@ViewBuilder
	var searchList: some View {
		List {
			ForEach(viewModel.filteredMediaAssetItems) { mediaAssetItem in
				MediaAssetItemSectionView(mediaAssetItem: mediaAssetItem) {
					#if os(visionOS)
					openWindow(value: mediaAssetItem)
					#else
					router.covered = .mediaPlayer(mediaAssetItem: mediaAssetItem)
					#endif
				}
				.contextMenu {
					ShareLink(items: mediaAssetItem.fileURLs.map { $0.standardizedFileURL })
				}
			}
		}
		.toolbarBackground(.hidden)
		.scrollContentBackground(.hidden)
		.listStyle(.inset)
	}

	@ViewBuilder
	var defaultList: some View {
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
		.onAppear {
			viewModel.fetchMediaAssetIndex()
		}
		.onCompletedDownload {
			viewModel.fetchMediaAssetIndex()
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
    }
}

#Preview {
	ContentView(router: .constant(Router()), currentSize: .constant(.zero))
        .environmentObject(UserPreferences.shared)
}
