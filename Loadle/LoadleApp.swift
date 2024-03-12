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
	@State private var currentSize: CGSize = .zero

    var body: some Scene {
        WindowGroup {
            ContentView(router: $router, currentSize: $currentSize)
                .environmentObject(userPreferences)
				.onChange(of: scenePhase) { _, newValue in
					handleScenePhase(scenePhase: newValue)
				}
        }

		#if os(visionOS)
		WindowGroup (id: "Download"){
			DownloadDestination()
				.environment(router)
				.environmentObject(userPreferences)
		}
		.defaultSize(CGSize(width: 30, height: currentSize.height))

		WindowGroup(for: URL.self) { $fileURL in
			MediaPlayerFactory.build(using: fileURL!)
				.environment(router)
				.environmentObject(userPreferences)
		}
		#endif
    }

	func handleScenePhase(scenePhase: ScenePhase) {
		switch scenePhase {
		case .background:
			log(.verbose, "App is in background.")
		case .inactive:
			log(.verbose, "App is inactive.")
		case .active:
			log(.verbose, "App is active.")
		@unknown default:
			fatalError()
		}
	}
}
