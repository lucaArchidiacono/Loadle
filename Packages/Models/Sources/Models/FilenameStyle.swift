//
//  FilenameStyle.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation

public enum FilenameStyle: String, Encodable {
    /// Default loadle file name pattern For example: `youtube_yPYZpwSpKmA_3840x2160_h264.mp4` or `youtube_yPYZpwSpKmA_audio.mp3`.
    case classic
    /// Title and Basic info in brackets. For example: `Video Title (2160p, h264).mp4` or `Audio Title - Audio Author.mp3`.
    case basic
    /// Tiltle and info in brackets. For example: `Video Title (2160p, h264, youtube).mp4` or `Audio Title - Audio Author (soundcloud).mp3`.
    case pretty
    /// Title and all info in brackets. For example: `Video Title (2160p, h264, youtube, yPYZpwSpKmA).mp4` or `Audio Title - Audio Author (soundcloud, 1242868615).mp3`.
    case nerdy
}
