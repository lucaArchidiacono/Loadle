//
//  ContentView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import Logger
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
		} detail: {
			if let selectedDestination {
				switch selectedDestination {
				case .downloads:
					DownloadDestination()
						.id(Destination.downloads)
				case .service(let service):
					ServiceDestination(service: service)
						.id(Destination.service(service: service))
				}
			} else {
				EmptyView()
			}
		}
		.navigationTitle(L10n.appTitle)
	}

	@ViewBuilder
	var downloads: some View {
		Section(L10n.downloadButtonTitle) {
			NavigationLink.empty {
				Label {
					Text("All")
				} icon: {
					Image(systemName: "icloud.and.arrow.down")
				}
			} onTap: {
				selectedDestination = .downloads
			}
			.tag(Destination.downloads)
		}
	}

	@ViewBuilder
	var servicesSection: some View {
		Section(L10n.servicesTitle) {
			ForEach(Service.allCases) { service in
				NavigationLink.empty {
					service.label
				} onTap: {
					selectedDestination = .service(service: service)
				}
				.tag(Destination.service(service: service))
			}
		}
	}
}

#Preview {
	ContentView(router: .constant(Router()))
		.environmentObject(Theme.shared)
		.environmentObject(UserPreferences.shared)
}
