//
//  AppRouting.swift
//  Loadle
//
//  Created by Luca Archidiacono on 07.02.2024.
//

import Foundation
import SwiftUI

@MainActor
extension View {
	@ViewBuilder
	private func build(_ destination: PathDestination) -> some View {
		switch destination {
		case .themeSelector:
			ThemeSelectorView()
		case .downloadDetail:
			EmptyView()
		}
	}

	@ViewBuilder
	private func build(_ destination: SheetDestination) -> some View {
		switch destination {
		case .settings:
			SettingsView()
		}
	}

	func withPath() -> some View {
		navigationDestination(for: PathDestination.self) { destination in
			build(destination)
		}
	}

	func withSheetDestinations(destination: Binding<SheetDestination?>) -> some View {
		sheet(item: destination) { destination in
			build(destination)
		}
	}

	func withCoverDestinations(destination: Binding<SheetDestination?>) -> some View {
		fullScreenCover(item: destination) { destination in
			build(destination)
		}
	}
}
