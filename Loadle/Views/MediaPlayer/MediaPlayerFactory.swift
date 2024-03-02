//
//  MediaPlayerFactory.swift
//  Loadle
//
//  Created by Luca Archidiacono on 02.03.2024.
//

import Foundation
import SwiftUI

@MainActor
struct MediaPlayerFactory {
    @ViewBuilder
    static func build(using fileURL: URL) -> some View {
        if fileURL.containsMovie || fileURL.containsVideo {
            VideoPlayerView(fileURL: fileURL)
        } else {
            EmptyView()
        }
    }
}
