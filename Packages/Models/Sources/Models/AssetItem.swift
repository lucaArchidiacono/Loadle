//
//  AssetItem.swift
//  Loadle
//
//  Created by Luca Archidiacono on 08.02.2024.
//

import Foundation
import Fundamentals
import Generator
import SwiftUI

public struct AssetItem: Identifiable {
    public let id: UUID
    public let fileURL: URL

    public var title: String { fileURL.lastPathComponent }
    public var image: Image {
        if fileURL.containsMovie {
            return Assets.movieIcon.swiftUIImage
        } else if fileURL.containsAudio {
            return Assets.audioIcon.swiftUIImage
        }
        return Image(systemName: "arrow.down.to.line.circle")
    }

    init(fileURL: URL) {
        id = UUID()
        self.fileURL = fileURL
    }
}

public extension AssetItem {
    static var previews: AssetItem {
        return AssetItem(fileURL: ResourceLoader.load(resource: ResourceLoader.Resource.jengaSkitMP3))
    }
}
