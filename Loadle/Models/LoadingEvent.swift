//
//  LoadingEvent.swift
//  Loadle
//
//  Created by Luca Archidiacono on 08.02.2024.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import REST

struct LoadingEvent: Identifiable {
	let id: UUID
	private(set) var url: URL
	private(set) var fileURL: URL?
	var image: Image {
		if let fileURL {
			if fileURL.containsMovie {
				return Asset.movieIcon.swiftUIImage
			} else if fileURL.containsAudio {
				return Asset.audioIcon.swiftUIImage
			}
		}

		return Image(systemName: "arrow.down.to.line.circle")
	}
	var title: String {
		if let fileURL = fileURL {
			return fileURL.lastPathComponent
		}
		return url.absoluteString
	}
	private(set) var state: REST.Download.State

	init(url: URL, state: REST.Download.State = .pending) {
		self.id = UUID()
		self.url = url
		self.state = state
	}

	mutating func update(state: REST.Download.State) {
		if case .success(let url) = state {
			self.fileURL = url
		}
		self.state = state
	}

	func isVideoFile(url: URL) -> Bool {
		let videoFileExtensions: Set<String> = ["mp4", "mov", "mkv", "avi", "wmv"] // Add more video file extensions as needed
		let fileExtension = url.pathExtension.lowercased()
		return videoFileExtensions.contains(fileExtension)
	}
}
