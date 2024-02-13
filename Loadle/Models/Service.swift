//
//  Service.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import SwiftUI

@MainActor
enum Service: String, Hashable, Identifiable, CaseIterable {
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

	nonisolated var id: String {
		rawValue
	}

	@ViewBuilder
	var label: some View {
		Label { text } icon: { icon }
	}

	var icon: some View {
		Self.color(for: self)
			.clipShape(Circle())
			.frame(width: 20, height: 20)
	}

	var text: some View {
		Text(Self.title(for: self))
	}

	static func color(for service: Service) -> Color {
		switch service {
		case .tiktok: return Color(red: 252/255, green: 0, blue: 118/255)
		case .youtube: return Color(red: 255/255, green: 0, blue: 0)
		case .instagram: return Color(red: 193/255, green: 53/255, blue: 132/255)
		case .twitter: return Color(red: 29/255, green: 161/255, blue: 242/255)
		case .reddit: return Color(red: 255/255, green: 87/255, blue: 34/255)
		case .twitch: return Color(red: 100/255, green: 65/255, blue: 164/255)
		case .pinterest: return Color(red: 203/255, green: 32/255, blue: 39/255)
		case .bilibili: return Color(red: 0, green: 188/255, blue: 1)
		case .soundcloud: return Color(red: 255/255, green: 85/255, blue: 0)
		case .okVideo: return Color(red: 255/255, green: 118/255, blue: 0)
		case .rutube: return Color(red: 0, green: 161/255, blue: 214/255)
		case .streamable: return Color(red: 0, green: 191/255, blue: 243/255)
		case .tumblr: return Color(red: 53/255, green: 70/255, blue: 92/255)
		case .vimeo: return Color(red: 26/255, green: 183/255, blue: 234/255)
		case .vine: return Color(red: 0, green: 180/255, blue: 137/255)
		case .vkVideos: return Color(red: 76/255, green: 117/255, blue: 163/255)
		}
	}

	static func title(for service: Service) -> String {
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