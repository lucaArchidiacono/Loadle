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
import BottomSheet
import Constants

struct ContentView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.scenePhase) var scenePhase
    @Environment(\.openWindow) private var openWindow
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@Environment(PlaylistService.self) private var playlistService

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
		.onChange(of: viewModel.state) { (oldState, newState) in
			switch newState {
			case .default:
				break
			case .selectedSingleMediaAssetItem:
				viewModel.isArchivingSheetPresented = true
			case .presentedArchivingSheet:
				break
			case .dismissedArchivingSheet:
				viewModel.isArchivingSheetPresented = false
			case .createdArchives:
				viewModel.isArchivingSheetPresented = false

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
		.onAppear {
			if preferences.showOnboarding {
				router.presented = .onboarding
			}
		}
		.environment(router)
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
					viewModel.selectedMediaAssetItems = [mediaAssetItem]
					viewModel.state = .selectedSingleMediaAssetItem
//						playlistService.select(mediaAssetItem, playlist: viewModel.filteredMediaAssetItems)
//
//						#if os(visionOS)
//						openWindow(id: "MediaPlayer")
//						#else
//						router.path.append(.mediaPlayer)
//						#endif
				}
			}
		}
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
			} onDismiss: {
				self.viewModel.state = .dismissedArchivingSheet
			}
		}
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
			InfoToolbar(placement: .topBarLeading) {
				router.presented = .info
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
			ForEach(MediaService.allServices) { service in
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
