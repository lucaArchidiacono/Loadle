//
//  LoadleApp.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import Environments
import REST
import SwiftData
import SwiftUI

@main
struct LoadleApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

//	@StateObject private var theme: Theme = .shared
	@StateObject private var userPreferences: UserPreferences = .shared

	@State private var downloadService: DownloadService = .shared
	@State private var notificationService: NotificationService = .shared
	@State private var mediaAssetService: MediaAssetService = .shared

	@State private var router: Router = .init()

    var body: some Scene {
        WindowGroup {
            ContentView(router: $router)
//                .applyTheme(theme)
                .environment(notificationService)
                .environment(downloadService)
                .environment(mediaAssetService)
//                .environmentObject(theme)
                .environmentObject(userPreferences)
        }
    }
}
