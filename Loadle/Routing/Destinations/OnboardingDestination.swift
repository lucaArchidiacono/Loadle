//
//  OnboardingDestination.swift
//  Loadle
//
//  Created by Luca Archidiacono on 15.03.2024.
//

import Environments
import Foundation
import SwiftUI

struct OnboardingDestination: View {
    @EnvironmentObject private var preferences: UserPreferences
    @Environment(Router.self) private var parentRouter: Router

    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            OnboardingView()
                .withPath()
                .withCoverDestinations(destination: $router.covered)
                .withSheetDestinations(destination: $router.presented)
        }
        .interactiveDismissDisabled(true)
        .onAppear {
            router.parent = parentRouter
        }
        .environment(router)
        .environmentObject(preferences)
    }
}
