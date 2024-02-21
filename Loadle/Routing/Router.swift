//
//  Router.swift
//  Loadle
//
//  Created by Luca Archidiacono on 07.02.2024.
//

import Foundation
import SwiftUI
import Models
import MessageUI

enum PathDestination: Hashable {
	case downloadDetail
}

enum SheetDestination: Hashable, Identifiable {
	case settings
	case download
	case mail(emailData: EmailData, onComplete: ((Result<MFMailComposeResult, Error>) -> Void)? = nil)

	var id: String {
		switch self {
		case .download:
			return "download"
		case .settings:
			return "settings"
		case .mail:
			return "mail"
		}
	}

	static func == (lhs: SheetDestination, rhs: SheetDestination) -> Bool {
		return lhs.id == rhs.id
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
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
