//
//  AudioFormat.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation

/// When `best` format is selected, you get audio the way it is on the service's side. It's not re-encoded. Everything else will be re-encoded.
enum AudioFormat: String, Encodable {
	case best = "best"
	case mp3 = "mp3"
	case ogg = "ogg"
	case wav = "wav"
	case opus = "opus"
}
