//
//  MediaService.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Constants
import Foundation
import Generator
import SwiftUI

public enum MediaService: String, Hashable, Identifiable, Codable {
	public static var allServices: [MediaService] {
		plusServices + freeServices
	}

	public static let freeServices: [MediaService] = [
		.soundcloud,
		.okVideo,
		.streamable,
		.vimeo,
		.vine,
		.vkVideos,
	]

	public static let plusServices: [MediaService] = [
		.tiktok,
		.youtube,
		.instagram,
		.twitter,
		.reddit,
		.twitch,
		.pinterest,
		.bilibili,
		.rutube,
		.tumblr,
	]

    case tiktok
    case youtube
    case instagram
    case twitter
    case reddit
    case twitch
    case pinterest
    case bilibili
    case soundcloud
    case okVideo
    case rutube
    case streamable
    case tumblr
    case vimeo
    case vine
    case vkVideos

    enum CodingKeys: String, CodingKey {
        case tiktok
        case youtube
        case instagram
        case twitter
        case reddit
        case twitch
        case pinterest
        case bilibili
        case soundcloud
        case okVideo
        case rutube
        case streamable
        case tumblr
        case vimeo
        case vine
        case vkVideos
    }

    public nonisolated var id: String {
        rawValue
    }

    public var title: String {
        Self.title(for: self)
    }

    public var regex: Constants.URLRegex.RawValue {
        switch self {
        case .tiktok: Constants.URLRegex.tiktok.rawValue
        case .youtube: Constants.URLRegex.youtube.rawValue
        case .instagram: Constants.URLRegex.instagram.rawValue
        case .twitter: Constants.URLRegex.twitter.rawValue
        case .reddit: Constants.URLRegex.reddit.rawValue
        case .twitch: Constants.URLRegex.twitchClips.rawValue
        case .pinterest: Constants.URLRegex.pinterest.rawValue
        case .bilibili: Constants.URLRegex.bilibili.rawValue
        case .soundcloud: Constants.URLRegex.soundcloud.rawValue
        case .okVideo: Constants.URLRegex.okVideo.rawValue
        case .rutube: Constants.URLRegex.rutube.rawValue
        case .streamable: Constants.URLRegex.streamable.rawValue
        case .tumblr: Constants.URLRegex.tumblr.rawValue
        case .vimeo: Constants.URLRegex.vimeo.rawValue
        case .vine: Constants.URLRegex.vineArchive.rawValue
        case .vkVideos: Constants.URLRegex.vkVideos.rawValue
        }
    }

	public var domain: Constants.Domain.RawValue {
		switch self {
		case .tiktok: Constants.Domain.tiktok.rawValue
		case .youtube: Constants.Domain.youtube.rawValue
		case .instagram: Constants.Domain.instagram.rawValue
		case .twitter: Constants.Domain.twitter.rawValue
		case .reddit: Constants.Domain.reddit.rawValue
		case .twitch: Constants.Domain.twitchClips.rawValue
		case .pinterest: Constants.Domain.pinterest.rawValue
		case .bilibili: Constants.Domain.bilibili.rawValue
		case .soundcloud: Constants.Domain.soundcloud.rawValue
		case .okVideo: Constants.Domain.okVideo.rawValue
		case .rutube: Constants.Domain.rutube.rawValue
		case .streamable: Constants.Domain.streamable.rawValue
		case .tumblr: Constants.Domain.tumblr.rawValue
		case .vimeo: Constants.Domain.vimeo.rawValue
		case .vine: Constants.Domain.vineArchive.rawValue
		case .vkVideos: Constants.Domain.vkVideos.rawValue
		}
	}

	@ViewBuilder
	public func label(count: Int?) -> some View {
		Label {
			HStack {
				text
				Spacer()
				if let count {
					Text("\(count)")
						.fontWeight(.light)
				}
			}
		} icon: {
			icon
		}

	}

    private var icon: some View {
        Self.color(for: self)
            .clipShape(Circle())
            .frame(width: 20, height: 20)
    }

    private var text: some View {
        Text(Self.title(for: self))
    }

    static func color(for service: MediaService) -> Color {
        switch service {
        case .tiktok: return Color(red: 252 / 255, green: 0, blue: 118 / 255)
        case .youtube: return Color(red: 255 / 255, green: 0, blue: 0)
        case .instagram: return Color(red: 193 / 255, green: 53 / 255, blue: 132 / 255)
        case .twitter: return Color(red: 29 / 255, green: 161 / 255, blue: 242 / 255)
        case .reddit: return Color(red: 255 / 255, green: 87 / 255, blue: 34 / 255)
        case .twitch: return Color(red: 100 / 255, green: 65 / 255, blue: 164 / 255)
        case .pinterest: return Color(red: 203 / 255, green: 32 / 255, blue: 39 / 255)
        case .bilibili: return Color(red: 0, green: 188 / 255, blue: 1)
        case .soundcloud: return Color(red: 255 / 255, green: 85 / 255, blue: 0)
        case .okVideo: return Color(red: 255 / 255, green: 118 / 255, blue: 0)
        case .rutube: return Color(red: 0, green: 161 / 255, blue: 214 / 255)
        case .streamable: return Color(red: 0, green: 191 / 255, blue: 243 / 255)
        case .tumblr: return Color(red: 53 / 255, green: 70 / 255, blue: 92 / 255)
        case .vimeo: return Color(red: 26 / 255, green: 183 / 255, blue: 234 / 255)
        case .vine: return Color(red: 0, green: 180 / 255, blue: 137 / 255)
        case .vkVideos: return Color(red: 76 / 255, green: 117 / 255, blue: 163 / 255)
        }
    }

    static func title(for service: MediaService) -> String {
        switch service {
        case .tiktok: return L10n.tiktok
        case .youtube: return L10n.youtube
        case .instagram: return L10n.instagram
        case .twitter: return L10n.twitter
        case .reddit: return L10n.reddit
        case .twitch: return L10n.twitch
        case .pinterest: return L10n.pinterest
        case .bilibili: return L10n.bilibili
        case .soundcloud: return L10n.soundcloud
        case .okVideo: return L10n.okVideo
        case .rutube: return L10n.rutube
        case .streamable: return L10n.streamable
        case .tumblr: return L10n.tumblr
        case .vimeo: return L10n.vimeo
        case .vine: return L10n.vine
        case .vkVideos: return L10n.vkVideo
        }
    }
}
