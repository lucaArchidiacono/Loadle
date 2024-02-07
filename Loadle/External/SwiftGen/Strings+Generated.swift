// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Localizable.strings
  ///   Loadle
  /// 
  ///   Created by Luca Archidiacono on 06.02.2024.
  internal static let appTitle = L10n.tr("Localizable", "app_title", fallback: "Loadle")
  /// Audio
  internal static let audio = L10n.tr("Localizable", "audio", fallback: "Audio")
  /// Auto
  internal static let auto = L10n.tr("Localizable", "auto", fallback: "Auto")
  /// Best
  internal static let best = L10n.tr("Localizable", "best", fallback: "Best")
  /// Dash
  internal static let dash = L10n.tr("Localizable", "dash", fallback: "Dash")
  /// Download
  internal static let downloadButtonTitle = L10n.tr("Localizable", "download_button_title", fallback: "Download")
  /// Max
  internal static let max = L10n.tr("Localizable", "max", fallback: "Max")
  /// Original
  internal static let original = L10n.tr("Localizable", "original", fallback: "Original")
  /// Paste link
  internal static let pasteLink = L10n.tr("Localizable", "paste_link", fallback: "Paste link")
  /// Progressive
  internal static let progressive = L10n.tr("Localizable", "progressive", fallback: "Progressive")
  /// Settings
  internal static let settings = L10n.tr("Localizable", "settings", fallback: "Settings")
  /// When "Best" format is selected, you get audio the way it is on service's side. It's not re-encoded. Everything else will be re-encoded.
  internal static let settingsAudioFormatDescription = L10n.tr("Localizable", "settings_audio_format_description", fallback: "When \"Best\" format is selected, you get audio the way it is on service's side. It's not re-encoded. Everything else will be re-encoded.")
  /// Format
  internal static let settingsAudioFormatHeader = L10n.tr("Localizable", "settings_audio_format_header", fallback: "Format")
  /// Removes audio from video downloads when possible.
  internal static let settingsAudioMuteDescription = L10n.tr("Localizable", "settings_audio_mute_description", fallback: "Removes audio from video downloads when possible.")
  /// Mute audio
  internal static let settingsAudioMuteTitle = L10n.tr("Localizable", "settings_audio_mute_title", fallback: "Mute audio")
  /// Downloads original sound used in the video without any additional changes by the post's author.
  internal static let settingsAudioTiktokDescriptionFullAudio = L10n.tr("Localizable", "settings_audio_tiktok_description_full_audio", fallback: "Downloads original sound used in the video without any additional changes by the post's author.")
  /// Full audio
  internal static let settingsAudioTiktokTitleFullAudio = L10n.tr("Localizable", "settings_audio_tiktok_title_full_audio", fallback: "Full audio")
  /// Original: Original video language is used.
  /// Auto: Default app language is used.
  /// 
  /// Defines which audio track will be used. If dubbed track isn't available, original video language is used instead.
  internal static let settingsAudioYoutubeDescriptionAudioTrack = L10n.tr("Localizable", "settings_audio_youtube_description_audio_track", fallback: "Original: Original video language is used.\nAuto: Default app language is used.\n\nDefines which audio track will be used. If dubbed track isn't available, original video language is used instead.")
  /// Audio Track
  internal static let settingsAudioYoutubeTitleAudioTrack = L10n.tr("Localizable", "settings_audio_youtube_title_audio_track", fallback: "Audio Track")
  /// If selected quality isn't available, closest one is used instead.
  internal static let settingsVideoQualityDescription = L10n.tr("Localizable", "settings_video_quality_description", fallback: "If selected quality isn't available, closest one is used instead.")
  /// Quality
  internal static let settingsVideoQualityTitle = L10n.tr("Localizable", "settings_video_quality_title", fallback: "Quality")
  /// Disable watermark
  internal static let settingsVideoTiktokTitleDisableWatermark = L10n.tr("Localizable", "settings_video_tiktok_title_disable_watermark", fallback: "Disable watermark")
  /// Converting looping videos to .gif reduces quality and majorly increases file size. If you want best efficiency, keep this setting off.
  internal static let settingsVideoTwitterDescriptionConvertGifsToGif = L10n.tr("Localizable", "settings_video_twitter_description_convert_gifs_to_gif", fallback: "Converting looping videos to .gif reduces quality and majorly increases file size. If you want best efficiency, keep this setting off.")
  /// Convert gifs to gif
  internal static let settingsVideoTwitterTitleConvertGifsToGif = L10n.tr("Localizable", "settings_video_twitter_title_convert_gifs_to_gif", fallback: "Convert gifs to gif")
  /// Progressive: Direct file link to Vimeo's cdn. max quality is 1080p.
  /// Dash: Video and audio are merged by cobalt into one file. max quality is 4k.
  /// 
  /// pick "Progressive" if you want best editor/player/social media compatibility. If "Progressive" download isn't available, "Dash" is used instead.
  internal static let settingsVideoVimeoDescriptionDownloadType = L10n.tr("Localizable", "settings_video_vimeo_description_download_type", fallback: "Progressive: Direct file link to Vimeo's cdn. max quality is 1080p.\nDash: Video and audio are merged by cobalt into one file. max quality is 4k.\n\npick \"Progressive\" if you want best editor/player/social media compatibility. If \"Progressive\" download isn't available, \"Dash\" is used instead.")
  /// Download Type
  internal static let settingsVideoVimeoTitleDownloadType = L10n.tr("Localizable", "settings_video_vimeo_title_download_type", fallback: "Download Type")
  /// H264: Generally better player support, but quality tops out at 1080p.
  /// AV1: Poor player support, but supports 8k & HDR.
  /// VP9: Usually highest bitrate, preserves most detail. Supports 4k & HDR.
  /// 
  /// pick H264 if you want best editor/player/social media compatibility.
  internal static let settingsVideoYoutubeDescriptionCodec = L10n.tr("Localizable", "settings_video_youtube_description_codec", fallback: "H264: Generally better player support, but quality tops out at 1080p.\nAV1: Poor player support, but supports 8k & HDR.\nVP9: Usually highest bitrate, preserves most detail. Supports 4k & HDR.\n\npick H264 if you want best editor/player/social media compatibility.")
  /// Codec
  internal static let settingsVideoYoutubeTitleCodec = L10n.tr("Localizable", "settings_video_youtube_title_codec", fallback: "Codec")
  /// TikTok
  internal static let tiktok = L10n.tr("Localizable", "tiktok", fallback: "TikTok")
  /// X/Twitter
  internal static let twitter = L10n.tr("Localizable", "twitter", fallback: "X/Twitter")
  /// Video
  internal static let video = L10n.tr("Localizable", "video", fallback: "Video")
  /// Vimeo
  internal static let vimeo = L10n.tr("Localizable", "vimeo", fallback: "Vimeo")
  /// Youtube
  internal static let youtube = L10n.tr("Localizable", "youtube", fallback: "Youtube")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
