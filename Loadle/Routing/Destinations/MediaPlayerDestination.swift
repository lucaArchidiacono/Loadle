//
//  MediaPlayerDestination.swift
//  Loadle
//
//  Created by Luca Archidiacono on 19.03.2024.
//

import Environments
import Foundation
import SwiftUI

struct MediaPlayerDestination: View {
	@EnvironmentObject private var preferences: UserPreferences
	@Environment(Router.self) private var parentRouter: Router
	@Environment(PlaylistService.self) private var playlistService: PlaylistService
	@State private var router = Router()

	var body: some View {
		NavigationStack(path: $router.path) {
			MediaPlayerView()
				.withPath()
				.withCoverDestinations(destination: $router.covered)
				.withSheetDestinations(destination: $router.presented)
		}
		.onAppear {
			router.parent = parentRouter
		}
		.environment(router)
		.environment(playlistService)
		.environmentObject(preferences)
	}
}
