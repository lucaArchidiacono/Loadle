//
//  MediaPlayerView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 02.03.2024.
//

import Foundation
import SwiftUI
import Models
import AVKit

@MainActor
struct MediaPlayerView: View {
    @State private var viewModel: MediaPlayerViewModel

    init(mediaAssetItem: MediaAssetItem) {
        self._viewModel = .init(wrappedValue: MediaPlayerViewModel(mediaAssetItem: mediaAssetItem))
    }
    
    var body: some View {
		VideoPlayer(player: viewModel.player)
    }
}

