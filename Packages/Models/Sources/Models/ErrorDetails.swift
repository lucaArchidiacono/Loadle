//
//  ErrorDetails.swift
//  Loadle
//
//  Created by Luca Archidiacono on 09.02.2024.
//

import Foundation

public struct ErrorDetails: Identifiable, Hashable {
    public enum Action: Hashable, Identifiable {
        case secondary(title: String, _ action: (() -> Void)? = nil)
        case primary(title: String, _ action: (() -> Void)? = nil)
        case destructive(title: String, _ action: (() -> Void)? = nil)

        public var id: String {
            switch self {
            case let .destructive(title, _):
                return "destructive:\(title)"
            case let .primary(title, _):
                return "primary:\(title)"
            case let .secondary(title, _):
                return "secondary:\(title)"
            }
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        public static func == (lhs: ErrorDetails.Action, rhs: ErrorDetails.Action) -> Bool {
            lhs.id == rhs.id
        }
    }

    public let id = UUID()
    public let title: String
    public let description: String
    public let actions: [Action]

    public init(title: String, description: String, actions: [Action]) {
        self.title = title
        self.description = description
        self.actions = actions
    }
}
