//
//  DownloadItem.swift
//  Loadle
//
//  Created by Luca Archidiacono on 13.02.2024.
//

import Foundation
import SwiftUI

public struct DownloadItem: Identifiable {
	public enum State {
		case pending
		case progress(currentBytes: Double, totalBytes: Double)
		case completed
		case cancelled
		case failed
	}

	public let id: UUID
	private(set) public var remoteURL: URL
	private(set) public var state: State

	public var title: String { remoteURL.absoluteString }
	public var image: Image { Image(systemName: "arrow.down.to.line.circle") }

	public init(remoteURL: URL) {
		self.id = UUID()
		self.state = .pending
		self.remoteURL = remoteURL
	}

	public mutating func update(state: State) {
		self.state = state
	}
}
