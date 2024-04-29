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
	case info

    var id: String {
        switch self {
		case .onboarding:
			return "onboarding"
		case .info:
			return "info"
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
	enum State {
		/// Indicates if the current View is presented as `Modal` on top of another view. It does also provide some additonal information,
		/// regarding if the current View is also the root of the `Modal` environment or not.
		case isPresented(isRoot: Bool)
		/// Indicates if the current View is presented as `Cover` on top of another view. It does also provide some additonal information,
		/// regarding if the current View is also the root of the `Cover` environment or not.
		case isCovered(isRoot: Bool)
		/// Indicates if the current View is presented via a push inside an `NavigationStack`.
		/// This View can be inside a `Modal` or `Cover` environment, but does not need necessary.
		case isPushed
		/// Indicates if the current View is the current root of a `NavigationStack`. Meaning it could cover, presenting on top of another View or be the actual first/root View.
		case isRoot
	}

    public var path: [PathDestination] = []
    public var presented: SheetDestination?
    public var covered: SheetDestination?

	public weak var parent: Router?

	/// Indicates if the current View is presented as `Modal` on top of another View. Meaning this view is now presenting on top another View.
	/// This does not mean that the current view is the root of the current `Modal` environment.
	/// It could be the root or pushed inside a NavigationStack which resides inside a View which is now presenting on top another View.
	/// To know if its currently the root view use either `isPushed`, `isRoot` or `state`.
	var isPresented: Bool { parent?.presented != nil }
	/// Indicates if the current View is presented as `Cover` on top of another view. Meaning this view is now covering another view.
	/// This does not mean that the current view is the root of the current `Cover` environment.
	/// It could be the root or pushed inside a NavigationStack which resides inside a View which is now covering another underlying View.
	/// To know if its currently the root view use either `isPushed`, `isRoot` or `state`.
	var isCovered: Bool { parent?.covered != nil }
	/// Indicates if the current View is presented via a push inside an `NavigationStack`.
	/// This View can be inside a `Modal` or `Cover` environment, but does not need necessary.
	var isPushed: Bool { !path.isEmpty }
	/// Indicates if the current View is the current root of a `NavigationStack`. Meaning it could cover, presenting on top of another View or be the actual first/root View.
	var isRoot: Bool { path.isEmpty }
	/// Indicates the current state of the View inside the RouterCoordinator's routing environment.
	var state: State {
		if isPresented {
			return .isPresented(isRoot: !isPushed)
		} else if isCovered {
			return .isCovered(isRoot: !isPushed)
		}
		return isPushed ? .isPushed : .isRoot
	}

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

	/// Uses the same behaviour like SwiftUI.
	/// The first case which results into a success will be executed.
	/// The order looks like following:
	/// 1. If path is not empty, then pop the first entry
	/// 2. If `presented` is not `nil`, dismiss
	/// 3. If covered is not `nil`, dismimss
	public func dismiss() {
		if isPushed {
			popLast(1)
		} else if isPresented {
			parent?.presented = nil
		} else if isCovered {
			parent?.covered = nil
		}
	}
}
