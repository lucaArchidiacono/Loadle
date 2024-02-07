//
//  Router.swift
//  Loadle
//
//  Created by Luca Archidiacono on 07.02.2024.
//

import Foundation
import SwiftUI

enum PathDestination: Hashable {
	case themeSelector
	case downloadDetail
}

enum SheetDestination: Hashable, Identifiable {
	case settings

	var id: String {
		switch self {
		case .settings:
			return "settings"
		}
	}
}

@MainActor
@Observable
final class Router {
	public var path: [PathDestination] = []
	public var presented: SheetDestination?
	public var covered: SheetDestination?

	public func navigate(_ to: PathDestination) {
		path.append(to)
	}

	public func popToRoot() {
		path.removeLast(path.count)
	}

	public func popLast(_ k: Int) {
		path.removeLast(k)
	}
}
