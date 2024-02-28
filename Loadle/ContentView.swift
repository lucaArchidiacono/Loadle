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
    @Environment(\.openWindow) private var openWindow
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var preferences: UserPreferences

    @State private var selectedDestination: Destination?

    @Binding var router: Router

    var body: some View {
        sidebarView
    }

    @ViewBuilder
    var sidebarView: some View {
        NavigationSplitView {
            List(selection: $selectedDestination) {
                servicesSection
            }
            .listStyle(.insetGrouped)
            .background(theme.secondaryBackgroundColor)
            .scrollContentBackground(.hidden)
            .navigationTitle(L10n.appTitle)
            .toolbar {
                SettingsToolbar(placement: .topBarLeading) {
                    router.presented = .settings
                }
                AddToolbar(placement: .topBarTrailing) {
                    router.presented = .download
                }
            }
            .withPath()
            .withSheetDestinations(destination: $router.presented)
            .withCoverDestinations(destination: $router.covered)
        } detail: {
            if let selectedDestination {
                switch selectedDestination {
                case let .media(service):
                    MediaDestination(service: service)
                        .id(Destination.media(service: service))
                }
            } else {
                EmptyView()
            }
        }
        .applyTheme(theme)
    }

    @ViewBuilder
    var servicesSection: some View {
        Section(L10n.mediaServicesTitle) {
            ForEach(MediaService.allCases) { service in
                NavigationLink(value: Destination.media(service: service)) {
                    service.label
                }
            }
        }
		.listRowBackground(theme.primaryBackgroundColor)
    }
}

#Preview {
    ContentView(router: .constant(Router()))
        .environmentObject(Theme.shared)
        .environmentObject(UserPreferences.shared)
}
