//
//  Tabs.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import SwiftUI

@MainActor
enum Tab: Int, Identifiable, Hashable, CaseIterable, Codable {
	case home

	nonisolated var id: Int {
		rawValue
	}

	@ViewBuilder
	func makeContentView() -> some View {
		switch self {
		case .home:
			HomeTab()
		}
	}

	@ViewBuilder
	var label: some View {
		switch self {
		case .home:
			Label("", systemImage: iconName)
		}
	}

	var iconName: String {
		switch self {
		case .home: "house.fill"
		}
	}
}

@Observable
class SidebarTabs {
	public static let shared = SidebarTabs()

	var tabs: [Tab] {
		[.home]
	}
}

@Observable
class iOSTabs {
	public static let shared = iOSTabs()

	var tabs: [Tab] {
		[.home]
	}
}
