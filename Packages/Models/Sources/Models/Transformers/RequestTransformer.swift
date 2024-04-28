//
//  RequestTransformer.swift
//
//
//  Created by Luca Archidiacono on 08.03.2024.
//

import Foundation

public extension DataTransformer {
	enum Request {}
}

public extension DataTransformer.Request {
	static func transform(
		url: URL,
		mediaService: MediaService,
		videoYoutubeCodec: YoutubeVideoCodec,
		videoDownloadQuality: DownloadVideoQuality,
		audioFormat: AudioFormat,
		audioOnly: Bool,
		videoTiktokWatermarkDisabled: Bool,
		audioTiktokFullAudio: Bool,
		audioMute: Bool,
		audioYoutubeTrack: YoutubeAudioTrack,
		videoTwitterConvertGifsToGif: Bool,
		videoVimeoDownloadType: ViemoDownloadVideoType
	) -> CobaltRequest {
		let cobaltRequest = CobaltRequest(
			url: transform(url, mediaService: mediaService),
			vCodec: videoYoutubeCodec,
			vQuality: videoDownloadQuality,
			aFormat: audioFormat,
			isAudioOnly: audioOnly,
			isNoTTWatermark: videoTiktokWatermarkDisabled,
			isTTFullAudio: audioTiktokFullAudio,
			isAudioMuted: audioMute,
			dubLang: audioYoutubeTrack == .original ? false : true,
			disableMetadata: false,
			twitterGif: videoTwitterConvertGifsToGif,
			vimeoDash: videoVimeoDownloadType == .progressive ? nil : true
		)
		return cobaltRequest
	}

	private static func transform(_ url: URL, mediaService: MediaService) -> URL {
		switch mediaService {
		case .tiktok:
			// Specify the list of query parameters to keep in the final URL
			let allowedParams = ["_d", "_r", "checksum"]

			// Get the components of the original URL
			if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
				// Filter and keep only the allowed query parameters
				components.queryItems = components.queryItems?.filter { item in
					allowedParams.contains(item.name)
				}

				// Create the transformed URL with the filtered query parameters
				if let transformedURL = components.url {
					return transformedURL
				}
			}
			return url
		case .youtube: return url
		case .instagram: return url
		case .twitter: return url
		case .reddit: return url
		case .twitch: return url
		case .pinterest: return url
		case .bilibili: return url
		case .soundcloud: return url
		case .okVideo: return url
		case .rutube: return url
		case .streamable: return url
		case .tumblr: return url
		case .vimeo: return url
		case .vine: return url
		case .vkVideos: return url
		}
	}
}
