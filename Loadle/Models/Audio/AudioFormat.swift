//
//  AudioFormat.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation

/// When `best` format is selected, you get audio the way it is on the service's side. It's not re-encoded. Everything else will be re-encoded.
enum AudioFormat: String, Encodable, CaseIterable {
    case best
    case mp3
    case ogg
    case wav
    case opus
}
