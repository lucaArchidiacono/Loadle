//
//  Router.swift
//  Loadle
//
//  Created by Luca Archidiacono on 07.02.2024.
//

import Foundation
import MessageUI
import Models
import SwiftUI

enum PathDestination: Hashable {
    case mediaPlayer
	case empty
}

enum SheetDestination: Hashable, Identifiable {
    case settings
    case download
    case mail(emailData: EmailData, onComplete: ((Result<MFMailComposeResult, Error>) -> Void)? = nil)
	case onboarding
	case paywall

    var id: String {
        switch self {
		case .onboarding:
			return "onboarding"
        case .download:
            return "download"
        case .settings:
            return "settings"
        case .mail:
            return "mail"
		case .paywall:
			return "paywall"
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

	public weak var parent: Router?

    public func navigate(_ to: PathDestination) {
        path.append(to)
    }

    public func popToRoot() {
        path.removeLast(path.count)
    }

    public func popLast(_ k: Int) {
        path.removeLast(k)
    }

	public func pop() {
		path.removeLast(1)
	}

	public func dismiss() {
		guard let parent = parent else {
			presented = nil
			covered = nil
			return
		}
		parent.dismiss()
	}
}
