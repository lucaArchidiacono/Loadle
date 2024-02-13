//
//  DownloadItem.swift
//  Loadle
//
//  Created by Luca Archidiacono on 13.02.2024.
//

import Foundation
import SwiftUI

struct DownloadItem: Identifiable {
	enum State {
		case pending
		case progress(currentBytes: Double, totalBytes: Double)
		case completed
		case cancelled
		case failed
	}

	let id: UUID
	private(set) var remoteURL: URL
	private(set) var state: State

	var title: String { remoteURL.absoluteString }
	var image: Image { Image(systemName: "arrow.down.to.line.circle") }

	init(remoteURL: URL) {
		self.id = UUID()
		self.state = .pending
		self.remoteURL = remoteURL
	}

	mutating func update(state: State) {
		self.state = state
	}

	func isVideoFile(url: URL) -> Bool {
		let videoFileExtensions: Set<String> = ["mp4", "mov", "mkv", "avi", "wmv"] // Add more video file extensions as needed
		let fileExtension = url.pathExtension.lowercased()
		return videoFileExtensions.contains(fileExtension)
	}
}
