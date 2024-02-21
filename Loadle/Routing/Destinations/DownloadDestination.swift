//
//  DownloadDestination.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Environments
import Foundation
import SwiftUI

struct DownloadDestination: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var preferences: UserPreferences
    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            DownloadView()
                .withPath()
                .withCoverDestinations(destination: $router.covered)
                .withSheetDestinations(destination: $router.presented)
        }
        .applyTheme(theme)
        .environment(router)
        .environmentObject(theme)
        .environmentObject(preferences)
    }
}
