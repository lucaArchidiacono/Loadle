//
//  VideoPlayerViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 02.03.2024.
//

import Foundation
import AVKit

@Observable
@MainActor
final class VideoPlayerViewModel {
    public var player: AVPlayer
    public var isPlaying: Bool = false
    
    init(fileURL: URL) {
        self.player = AVPlayer(url: fileURL)
    }
}
