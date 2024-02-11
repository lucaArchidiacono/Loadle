//
//  LoadleApp.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import REST
import SwiftData
import SwiftUI

@main
struct LoadleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State var theme = Theme.shared
    @State var preferences = UserPreferences.shared

	@State var selectedTab: Tab = .home
	@State var router: Router = Router()

    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab, router: $router)
                .environmentObject(theme)
                .environmentObject(preferences)
        }
    }
}
