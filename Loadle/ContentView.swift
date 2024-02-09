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
	@State private var audioOnly: Bool = false

	init() {
		UITextField.appearance().clearButtonMode = .whileEditing
	}

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
						downloadManager.startDownload(using: url, preferences: preferences, audioOnly: audioOnly)
					} label: {
						Text(L10n.downloadButtonTitle)
							.frame(maxWidth: .infinity)
							.padding(.horizontal)
							.padding(.vertical, 10)
					}
					.buttonStyle(.borderedProminent)
					.padding(.horizontal)
					.padding(.bottom, 10)

					Toggle(isOn: $audioOnly) {
						Text(L10n.downloadAudioOnly)
					}
					.toggleStyle(iOSCheckboxToggleStyle())
					.padding(.bottom, 10)

					List(downloadManager.loadingEvents, id: \.id) { event in
						let view = DownloadTaskSectionView(
							title: event.title,
							image: event.image,
							state: event.state,
							onPause: {
								downloadManager.pauseDownload(for: event)
							},
							onResume: {
								downloadManager.resumeDownload(for: event)
							})
							.swipeActions(edge: .trailing) {
								Button(role: .destructive, 
									   action: { downloadManager.delete(for: event) } ,
									   label: { Image(systemName: "trash") } )
							}
						if let fileURL = event.fileURL {
							view
								.contextMenu {
									ShareLink(item: fileURL)
								}
						} else {
							view
						}
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
