//
//  YoutubeVideoCodec.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation

/// Pick `h246` if you want best editor/player/social media compatibility.
enum YoutubeVideoCodec: String, Encodable {
	/// MP4. Generally better player support, but quality tops out at 1080p.
	case h264 = "h264"
	/// MP4. Poor player support, but supports 8k & HDR.
	case av1 = "av1"
	/// WEBM. Usually highest bitrate, perserves most detail. Supports 4k & HDR.
	case vp9 = "vp9"
}
