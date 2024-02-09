//
//  LoadingEvent.swift
//  Loadle
//
//  Created by Luca Archidiacono on 08.02.2024.
//

import Foundation

struct LoadingEvent: Identifiable {
	let id: UUID
	let url: URL
	var title: String {
		if case .success(let url) = state {
			return String(url.lastPathComponent.prefix(20)) + "..."
		} else {
			return String(url.absoluteString.prefix(20)) + "..."
		}
	}
	private(set) var state: Download.State = .pending

	init(url: URL) {
		self.id = UUID()
		self.url = url
	}

	mutating func update(state: Download.State) {
		self.state = state
	}
}
