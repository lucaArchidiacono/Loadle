//
//  ContentView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import Logger
import SwiftUI

struct ContentView: View {
	@Environment(DownloadManager.self) private var downloadManager
	@EnvironmentObject private var preferences: UserPreferences
	@EnvironmentObject private var theme: Theme

	@State private var router: Router = Router()
	@State private var url: String = ""

	var body: some View {
		NavigationStack(path: $router.path) {
			ZStack {
				VStack {
					Spacer()
					HStack {
						Image(systemName: "link")
						TextField(L10n.pasteLink, text: $url)
					}
					.padding()
					.background(theme.secondaryBackgroundColor)
					.cornerRadius(8)
					.padding(.horizontal)
					.padding(.vertical, 10)
					.foregroundColor(theme.tintColor)

					Button {
						if let url = URL(string: url) {
							downloadManager.startDownload(using: url, preferences: preferences)
						} else {
							log(.error, "No real url")
						}
					} label: {
						Text(L10n.downloadButtonTitle)
							.frame(maxWidth: .infinity)
							.padding(.horizontal)
							.padding(.vertical, 10)
					}
					.buttonStyle(.borderedProminent)
					.padding(.horizontal)

					List(downloadManager.loadingEvents, id: \.id) { event in
						DownloadTaskView(
							title: event.title,
							state: event.state,
							onPause: {
								downloadManager.pauseDownload(for: event)
							},
							onResume: {
								downloadManager.resumeDownload(for: event)
							})
					}
					.scrollContentBackground(.hidden)
				}
			}
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						router.presented = .settings
					} label: {
						Image(systemName: "gear")
					}
				}
			}
			.navigationBarTitle(L10n.appTitle)
			.background(theme.primaryBackgroundColor)
		}
		.applyTheme(theme)
		.withSheetDestinations(destination: $router.presented)
		.withCoverDestinations(destination: $router.covered)
    }
}

#Preview {
	ContentView()
		.environment(DownloadManager.shared)
		.environmentObject(Theme.shared)
		.environmentObject(UserPreferences.shared)
}
