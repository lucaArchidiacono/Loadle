//
//  LoadingEvent.swift
//  Loadle
//
//  Created by Luca Archidiacono on 08.02.2024.
//

import Foundation

struct LoadingEvent: Identifiable {
	let id: UUID
	private(set) var url: URL
	var title: String {
		if url.isFileURL {
			return url.lastPathComponent
		}
		return url.lastPathComponent
	}
	private(set) var state: Download.State

	init(url: URL, state: Download.State = .pending) {
		self.id = UUID()
		self.url = url
		self.state = state
	}

	mutating func update(state: Download.State) {
		if case .success(let url) = state {
			self.url = url
		}
		self.state = state
	}
}
