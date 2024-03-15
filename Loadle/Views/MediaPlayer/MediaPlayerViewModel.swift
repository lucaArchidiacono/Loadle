//
//  MediaPlayerViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 02.03.2024.
//

import Foundation
import Models
import Logger
import AVKit

@Observable
@MainActor
final class MediaPlayerViewModel {
    public var player: AVPlayer?
    public var isPlaying: Bool = false
	public var mediaAssetItem: MediaAssetItem

    init(mediaAssetItem: MediaAssetItem) {
		self.mediaAssetItem = mediaAssetItem
		self.player = AVPlayer(url: mediaAssetItem.fileURLs[0])
		
		do {
			try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
		} catch {
			log(.error, error)
		}
    }
}
