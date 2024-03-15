//
//  SettingsDestination.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Environments
import Foundation
import SwiftUI

struct SettingsDestination: View {
    @EnvironmentObject private var preferences: UserPreferences
	@Environment(Router.self) private var parentRouter: Router
    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            SettingsView()
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
