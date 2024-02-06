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

  var body: some Scene {
    WindowGroup {
      ContentView()
        .applyTheme(theme)
        .environment(appDelegate.downloadManager)
        .environmentObject(theme)
        .environmentObject(preferences)
    }
  }
}
