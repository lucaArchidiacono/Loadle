//
//  UserPreferences.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation
import Models
import SwiftUI

@MainActor
public final class UserPreferences: ObservableObject {
    public static let shared = UserPreferences()

	@AppStorage("show_onboarding") public var showOnboarding = true

    /// Feedback Settings
    @AppStorage("haptic_button_press") public var hapticButtonPressEnabled = true
    @AppStorage("sound_effect_enabled") public var soundEffectEnabled = true

    /// Filename Settings
    @AppStorage("filename_style") public var filenameStyle: FilenameStyle = .basic

    /// Video Download Settings
    @AppStorage("video_download_quality") public var videoDownloadQuality: DownloadVideoQuality = ._1080
    @AppStorage("video_youtube_codec") public var videoYoutubeCodec: YoutubeVideoCodec = .h264
    @AppStorage("video_vimeo_download_type") public var videoVimeoDownloadType: ViemoDownloadVideoType = .progressive
    @AppStorage("video_tiktok_watermark_disabled") public var videoTiktokWatermarkDisabled: Bool = false
    @AppStorage("video_twitter_convert_gifs_to_gif") public var videoTwitterConvertGifsToGif: Bool = false

    /// Audio Download Settings
    @AppStorage("audio_format") public var audioFormat: AudioFormat = .mp3
    @AppStorage("audio_youtube_track") public var audioYoutubeTrack: YoutubeAudioTrack = .original
    @AppStorage("audio_mute") public var audioMute: Bool = false
    @AppStorage("audio_tiktok_full_audio") public var audioTiktokFullAudio: Bool = false

    private init() {}
}
