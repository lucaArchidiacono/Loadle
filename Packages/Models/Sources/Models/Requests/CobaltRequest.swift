//
//  CobaltRequest.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation

public struct CobaltRequest: Codable {
    public let url: URL
    public let vCodec: YoutubeVideoCodec
    public let vQuality: DownloadVideoQuality
    public let aFormat: AudioFormat
    public let filenamePattern: FilenameStyle
    public let isAudioOnly: Bool
    public let isNoTTWatermark: Bool
    public let isTTFullAudio: Bool
    public let isAudioMuted: Bool
    public let dubLang: Bool
    public let disableMetadata: Bool
    public let twitterGif: Bool
    public let vimeoDash: Bool?

    public init(url: URL, vCodec: YoutubeVideoCodec, vQuality: DownloadVideoQuality, aFormat: AudioFormat, isAudioOnly: Bool, isNoTTWatermark: Bool, isTTFullAudio: Bool, isAudioMuted: Bool, dubLang: Bool, disableMetadata: Bool, twitterGif: Bool, vimeoDash: Bool?) {
        self.url = url
        self.vCodec = vCodec
        self.vQuality = vQuality
        self.aFormat = aFormat
        self.isAudioOnly = isAudioOnly
        self.isNoTTWatermark = isNoTTWatermark
        self.isTTFullAudio = isTTFullAudio
        self.isAudioMuted = isAudioMuted
        self.dubLang = dubLang
        self.disableMetadata = disableMetadata
        self.twitterGif = twitterGif
        self.vimeoDash = vimeoDash
        filenamePattern = .pretty
    }
}
