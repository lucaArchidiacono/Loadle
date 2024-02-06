//
//  YoutubeAudioTrack.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation

/// Defines which audio track will be sued. If dubbed track isn't available, original video language is used instead.
enum YoutubeAudioTrack: String, Encodable {
  /// Original video language is used.
  case original
  /// Default device (and cobalt) language is used
  case auto
}
