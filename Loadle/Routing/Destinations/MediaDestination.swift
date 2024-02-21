//
//  MediaDestination.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Environments
import Foundation
import Models
import SwiftUI

struct MediaDestination: View {
    @EnvironmentObject private var theme: Theme
    @EnvironmentObject private var preferences: UserPreferences
    @State private var router = Router()

    let service: MediaService

    var body: some View {
        NavigationStack(path: $router.path) {
            MediaView(service: service)
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
