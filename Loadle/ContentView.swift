//
//  ContentView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import Logger
import REST
import SwiftData
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


					Button {
						if let url = URL(string: url) {
							downloadManager.startDownload(using: url, preferences: preferences)
						} else {
							log(.error, "No real url")
						}
					} label: {
						Text(L10n.downloadButtonTitle)
							.padding(.horizontal)
							.padding(.vertical, 10)
							.cornerRadius(8)
					}
					.shadow(radius: 30)
					.padding()

					List(downloadManager.downloads, id: \.id) { task in
						@State var state: REST.DownloadTask.State = .pending
						DownloadTaskView(
							url: task.url,
							state: state,
							onCancel: {
								task.cancel()
							},
							onResumeCanceled: {
								task.resumeCanceled()
							})
						.onAppear {
							task.onStateChange = { newState in
								DispatchQueue.main.async {
									state = newState
								}
							}
						}
					}
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
