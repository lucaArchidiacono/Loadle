//
//  ErrorDetails.swift
//  Loadle
//
//  Created by Luca Archidiacono on 09.02.2024.
//

import Foundation

struct ErrorDetails {
	enum Action: Hashable, Identifiable {
		case secondary(title: String, _ action: (() -> Void)? = nil)
		case primary(title: String, _ action: (() -> Void)? = nil)
		case destructive(title: String, _ action: (() -> Void)? = nil)

		var id: String {
			switch self {
			case .destructive(let title, _):
				return "destructive:\(title)"
			case .primary(let title, _):
				return "primary:\(title)"
			case .secondary(let title, _):
				return "secondary:\(title)"
			}
		}

		func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}

		static func == (lhs: ErrorDetails.Action, rhs: ErrorDetails.Action) -> Bool {
			lhs.id == rhs.id
		}
	}
	let title: String
	let description: String
	let actions: [Action]
}
