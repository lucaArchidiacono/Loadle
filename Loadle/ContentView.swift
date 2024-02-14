//
//  ContentView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import Logger
import Environments
import Generator
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
				downloads
				servicesSection
			}
			.listStyle(.insetGrouped)
			.background(theme.secondaryBackgroundColor)
			.scrollContentBackground(.hidden)
			.navigationTitle(L10n.appTitle)
		} detail: {
			if let selectedDestination {
				switch selectedDestination {
				case .downloads:
					DownloadDestination()
						.id(Destination.downloads)
				case .media(let service):
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
	var downloads: some View {
		Section(L10n.downloadButtonTitle) {
			NavigationLink(value: Destination.downloads) {
				Label {
					Text(L10n.all)
				} icon: {
					Image(systemName: "icloud.and.arrow.down")
				}

			}
		}
	}

	@ViewBuilder
	var servicesSection: some View {
		Section(L10n.servicesTitle) {
			ForEach(Service.allCases) { service in
				NavigationLink(value: Destination.media(service: service)) {
					service.label
				}
			}
		}
	}
}

#Preview {
	ContentView(router: .constant(Router()))
		.environmentObject(Theme.shared)
		.environmentObject(UserPreferences.shared)
}
