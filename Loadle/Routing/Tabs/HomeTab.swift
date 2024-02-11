//
//  HomeTab.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import SwiftUI

struct HomeTab: View {
	@EnvironmentObject private var theme: Theme
	@EnvironmentObject private var preferences: UserPreferences
	@State private var router = Router()

	var body: some View {
		NavigationStack(path: $router.path) {
			HomeView()
				.withPath()
				.withCoverDestinations(destination: $router.covered)
				.withSheetDestinations(destination: $router.presented)
		}
		.environment(router)
	}
}
