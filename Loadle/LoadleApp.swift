//
//  LoadleApp.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import Environments
import REST
import Logger
import SwiftUI

@main
struct LoadleApp: App {
	@UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

	@Environment(\.scenePhase) private var scenePhase

	@StateObject private var userPreferences: UserPreferences = .shared

	@State private var downloadService: DownloadService = .shared
	@State private var notificationService: NotificationService = .shared

	@State private var router: Router = .init()

    var body: some Scene {
        WindowGroup {
            ContentView(router: $router)
                .environmentObject(userPreferences)
				.onChange(of: scenePhase) { _, newValue in
					handleScenePhase(scenePhase: newValue)
				}
        }
    }

	func handleScenePhase(scenePhase: ScenePhase) {
		switch scenePhase {
		case .background:
			log(.verbose, "App is in background.")
			#if DEBUG
				exit(0)
			#endif
		case .inactive:
			log(.verbose, "App is inactive.")
		case .active:
			log(.verbose, "App is active.")
		@unknown default:
			fatalError()
		}
	}
}
