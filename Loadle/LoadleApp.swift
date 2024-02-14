//
//  LoadleApp.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import REST
import SwiftData
import Environments
import SwiftUI

@main
struct LoadleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State var theme = Theme.shared
    @State var preferences = UserPreferences.shared

	@State var router: Router = Router()

    var body: some Scene {
        WindowGroup {
			ContentView(router: $router)
				.environment(appDelegate.notificationService)
				.environment(appDelegate.downloadService)
                .environmentObject(theme)
                .environmentObject(preferences)
        }
    }
}
