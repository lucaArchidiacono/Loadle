//
//  LoadleApp.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import Environments
import REST
import Logger
import Models
import SwiftUI

@main
struct LoadleApp: App {
	@UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

	@Environment(\.scenePhase) private var scenePhase

	@StateObject private var userPreferences: UserPreferences = .shared

	@State private var playlistService: PlaylistService = .shared
	@State private var appState: AppState = .shared

	@State private var router: Router = .init()
	@State private var currentSize: CGSize = .zero

    var body: some Scene {
        WindowGroup {
            ContentView(router: $router, currentSize: $currentSize)
				.environment(appState)
				.environment(playlistService)
				.environmentObject(userPreferences)
				.onChange(of: scenePhase) { _, newValue in
					handleScenePhase(scenePhase: newValue)
				}
        }

		#if os(visionOS)
		WindowGroup(id: "Download"){
			DownloadDestination()
				.environment(appState)
				.environment(router)
				.environment(playlistService)
				.environmentObject(userPreferences)
		}
		.defaultSize(CGSize(width: 30, height: currentSize.height))

		WindowGroup(id: "MediaPlayer") {
			MediaPlayerDestination()
				.environment(appState)
				.environment(router)
				.environment(playlistService)
				.environmentObject(userPreferences)
		}
		#endif
    }

	func handleScenePhase(scenePhase: ScenePhase) {
		switch scenePhase {
		case .background:
			log(.info, "App is in background.")
		case .inactive:
			log(.info, "App is inactive.")
		case .active:
			log(.info, "App is active.")
		@unknown default:
			fatalError()
		}
	}
}
