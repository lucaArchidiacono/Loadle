//
//  Preferences.swift
//
//
//  Created by Luca Archidiacono on 02.03.2024.
//

import Foundation

public struct Preferences {
    public var audioOnly: Bool

    /// Filename Settings
    public var filenameStyle: FilenameStyle

    /// Video Download Settings
    public var videoDownloadQuality: DownloadVideoQuality
    public var videoYoutubeCodec: YoutubeVideoCodec
    public var videoVimeoDownloadType: ViemoDownloadVideoType
    public var videoTiktokWatermarkDisabled: Bool
    public var videoTwitterConvertGifsToGif: Bool

    /// Audio Download Settings
    public var audioFormat: AudioFormat
    public var audioYoutubeTrack: YoutubeAudioTrack
    public var audioMute: Bool
    public var audioTiktokFullAudio: Bool

    public init(audioOnly: Bool, filenameStyle: FilenameStyle, videoDownloadQuality: DownloadVideoQuality, videoYoutubeCodec: YoutubeVideoCodec, videoVimeoDownloadType: ViemoDownloadVideoType, videoTiktokWatermarkDisabled: Bool, videoTwitterConvertGifsToGif: Bool, audioFormat: AudioFormat, audioYoutubeTrack: YoutubeAudioTrack, audioMute: Bool, audioTiktokFullAudio: Bool) {
        self.audioOnly = audioOnly
        self.filenameStyle = filenameStyle
        self.videoDownloadQuality = videoDownloadQuality
        self.videoYoutubeCodec = videoYoutubeCodec
        self.videoVimeoDownloadType = videoVimeoDownloadType
        self.videoTiktokWatermarkDisabled = videoTiktokWatermarkDisabled
        self.videoTwitterConvertGifsToGif = videoTwitterConvertGifsToGif
        self.audioFormat = audioFormat
        self.audioYoutubeTrack = audioYoutubeTrack
        self.audioMute = audioMute
        self.audioTiktokFullAudio = audioTiktokFullAudio
    }
}
