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
    var servicesSection: some View {
        Section(L10n.mediaServicesTitle) {
            ForEach(MediaService.allCases) { service in
                NavigationLink(value: Destination.media(service: service)) {
					service.label(count: viewModel.mediaAssetsCount[service])
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
