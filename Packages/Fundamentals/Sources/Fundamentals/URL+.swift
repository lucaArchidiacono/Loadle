//
//  URL+.swift
//  Loadle
//
//  Created by Luca Archidiacono on 09.02.2024.
//

import Foundation
import UniformTypeIdentifiers

public extension URL {
    func matchesRegex(pattern: String) -> Bool {
        do {
            let regexV1 = try Regex(pattern)
            return (try? regexV1.firstMatch(in: absoluteString)) != nil
        } catch {
            return false
        }
    }

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
			return type.conforms(to: .movie) || type.conforms(to: .video) // ex. .mp4-movies
        }
        return false
    }
}
