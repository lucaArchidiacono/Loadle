//
//  LoadingEvent.swift
//  Loadle
//
//  Created by Luca Archidiacono on 08.02.2024.
//

import Foundation
import SwiftUI

struct LoadingEvent: Identifiable {
	let id: UUID
	private(set) var url: URL
	private(set) var fileURL: URL?
	private(set) var image: Image
	var title: String {
		if let fileURL = fileURL {
			return fileURL.lastPathComponent
		}
		return url.absoluteString
	}
	private(set) var state: Download.State

	init(url: URL, state: Download.State = .pending) {
		self.id = UUID()
		self.url = url
		self.state = state

		
	}

	mutating func update(state: Download.State) {
		if case .success(let url) = state {
			self.fileURL = url
		}
		self.state = state
	}
}
