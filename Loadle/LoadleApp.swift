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

    @State var router: Router = .init()

    var body: some Scene {
        WindowGroup {
            ContentView(router: $router)
                .applyTheme(appDelegate.theme)
                .environment(appDelegate.notificationService)
                .environment(appDelegate.downloadService)
                .environmentObject(appDelegate.theme)
                .environmentObject(appDelegate.preferences)
        }
    }
}
