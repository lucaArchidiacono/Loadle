//
//  ServiceDestination.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import SwiftUI

struct ServiceDestination: View {
	@EnvironmentObject private var theme: Theme
	@EnvironmentObject private var preferences: UserPreferences
	@State private var router = Router()

	let service: Service

	var body: some View {
		NavigationStack(path: $router.path) {
			ServiceView(service: service)
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
