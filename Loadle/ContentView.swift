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

	@State private var url: String = ""
	@State private var isSettingsVisible: Bool = false

	var body: some View {
		NavigationView {
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
						DownloadTaskView(
							url: task.url,
							state: task.state,
							onCancel: {
								task.cancel()
							},
							onResumseCanceled: {
								task.resumeCanceled()
							})
					}
				}
			}
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						isSettingsVisible.toggle()
					} label: {
						Image(systemName: "gear")
					}
				}
			}
			.navigationBarTitle(L10n.appTitle)
			.background(theme.primaryBackgroundColor)
		}
		.sheet(isPresented: $isSettingsVisible) {
			SettingsView()
		}
		.applyTheme(theme)
    }
}

#Preview {
	ContentView()
		.environment(DownloadManager(downloader: REST.Downloader(), loader: REST.Loader()))
		.environmentObject(Theme.shared)
		.environmentObject(UserPreferences.shared)
}
