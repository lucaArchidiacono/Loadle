//
//  VideoPlayerView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 02.03.2024.
//

import Foundation
import SwiftUI
import AVKit

@MainActor
struct VideoPlayerView: View {
    @State private var viewModel: VideoPlayerViewModel
    
    init(fileURL: URL) {
        self._viewModel = .init(wrappedValue: VideoPlayerViewModel(fileURL: fileURL))
    }
    
    var body: some View {
            VideoPlayer(player: viewModel.player)
    }
}

