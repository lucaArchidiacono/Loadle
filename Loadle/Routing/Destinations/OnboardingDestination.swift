//
//  OnboardingDestination.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Environments
import Foundation
import SwiftUI

struct OnboardingDestination: View {
    @EnvironmentObject private var preferences: UserPreferences

    var body: some View {
        NavigationView {
            SettingsView()
        }
        .environmentObject(preferences)
    }
}
