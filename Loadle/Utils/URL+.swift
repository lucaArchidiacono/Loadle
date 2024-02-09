//
//  URL+.swift
//  Loadle
//
//  Created by Luca Archidiacono on 09.02.2024.
//

import Foundation
import UniformTypeIdentifiers

extension URL {
	func mimeType() -> String {
		let pathExtension = self.pathExtension
		if let type = UTType(filenameExtension: pathExtension) {
			if let mimetype = type.preferredMIMEType {
				return mimetype as String
			}
		}
		return "application/octet-stream"
	}

	var containsImage: Bool {
		let mimeType = self.mimeType()
		if let type = UTType(mimeType: mimeType) {
			return type.conforms(to: .image)
		}
		return false
	}

	var containsAudio: Bool {
		let mimeType = self.mimeType()
		if let type = UTType(mimeType: mimeType) {
			return type.conforms(to: .audio)
		}
		return false
	}

	var containsMovie: Bool {
		let mimeType = self.mimeType()
		if let type = UTType(mimeType: mimeType) {
			return type.conforms(to: .movie)   // ex. .mp4-movies
		}
		return false
	}

	var containsVideo: Bool {
		let mimeType = self.mimeType()
		if let type = UTType(mimeType: mimeType) {
			return type.conforms(to: .video)
		}
		return false
	}
}
