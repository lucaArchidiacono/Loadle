//
//  InfoDestination.swift
//  Loadle
//
//  Created by Luca Archidiacono on 29.04.2024.
//

import Environments
import Foundation
import SwiftUI

struct InfoDestination: View {
    @EnvironmentObject private var preferences: UserPreferences
    @Environment(Router.self) private var parentRouter: Router
    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            InfoView()
                .withPath()
                .withCoverDestinations(destination: $router.covered)
                .withSheetDestinations(destination: $router.presented)
        }
        .onAppear {
            router.parent = parentRouter
        }
        .environment(router)
        .environmentObject(preferences)
    }
}
