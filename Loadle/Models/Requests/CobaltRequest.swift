//
//  CobaltRequest.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation

struct CobaltRequest: Encodable {
	public let url: URL
	public let vCodec: YoutubeVideoCodec
	public let vQuality: DownloadVideoQuality
	public let aFormat: AudioFormat
	public let filenamePattern: FilenameStyle = .pretty
	public let isAudioOnly: Bool
	public let isNoTTWatermark: Bool
	public let isTTFullAudio: Bool
	public let isAudioMuted: Bool
	public let dubLang: Bool
	public let disableMetadata: Bool
	public let twitterGif: Bool
	public let vimeoDash: Bool?
}
