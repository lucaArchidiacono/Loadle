//
//  InfoView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 29.04.2024.
//

import Foundation
import SwiftUI
import Constants
import Models
import Generator

struct InfoView: View {
	@Environment(Router.self	) private var router: Router

	private static var header = [
		L10n.mediaServicesTitle,
		L10n.video + "/" + L10n.audio,
		L10n.audio,
		L10n.video,
		L10n.image,
		L10n.appProductPlus
	]

	private static var services = [
		MediaService.bilibili: ["Bilibili.com & Bilibili.tv", "✅", "✅", "✅", "➖"],
		MediaService.instagram: ["Instagram Reels & Posts & Stories", "✅", "✅", "✅", "➖"],
		MediaService.okVideo: ["OK Video", "✅", "❌", "❌", "✅"],
		MediaService.pinterest: ["Pinterest", "✅", "✅", "✅", "➖"],
		MediaService.reddit: ["Reddit", "✅", "✅", "✅", "❌"],
		MediaService.rutube: ["Rutube", "✅", "✅", "✅", "✅"],
		MediaService.soundcloud: ["Soundcloud", "➖", "✅", "➖", "✅"],
		MediaService.streamable: ["Streamable", "✅", "✅", "✅", "➖"],
		MediaService.tiktok: ["Tiktok", "✅", "✅", "✅", "❌"],
		MediaService.tumblr: ["Tumblr", "✅", "✅", "✅", "➖"],
		MediaService.twitch: ["Twitch Clips", "✅", "✅", "✅", "✅"],
		MediaService.twitter: ["Twitter/X", "✅", "✅", "✅", "➖"],
		MediaService.vimeo: ["Vimeo", "✅", "✅", "✅", "✅"],
		MediaService.vine: ["Vine Archive", "✅", "✅", "✅", "➖"],
		MediaService.vkVideos: ["VK Videos & Clips", "✅", "❌", "❌", "✅"],
		MediaService.youtube: ["Youtube Videos, Shorts & Music", "✅", "✅", "✅", "✅"]
	]

	private static var plusServices: [MediaService: [String]] {
		return services
			.reduce(into: [MediaService: [String]]()) { partialResult, tuple in
				let (key, array) = tuple
				guard MediaService.plusServices.contains(key) else { return }
				partialResult[key] = array
				partialResult[key]?.append("✅")
			}
	}

	private static var freeServices: [MediaService: [String]] {
		return services
			.reduce(into: [MediaService: [String]]()) { partialResult, tuple in
				let (key, array) = tuple
				guard MediaService.freeServices.contains(key) else { return }
				partialResult[key] = array
				partialResult[key]?.append("➖")
			}
	}

	private static var allServices: [[String]] {
		let _plusServices = plusServices
			.values
			.map { $0 }
		let _freeServices = freeServices
			.values
			.map { $0 }
		let allServices = _plusServices + _freeServices
		return allServices.sorted(by: { $0[0] < $1[0] })
	}

	private var gridItems: [GridItem] {
		[
			GridItem(.flexible(minimum: 100, maximum: .infinity)),
			GridItem(.flexible(minimum: 10, maximum: .infinity)),
			GridItem(.flexible(minimum: 10, maximum: .infinity)),
			GridItem(.flexible(minimum: 10, maximum: .infinity)),
			GridItem(.flexible(minimum: 10, maximum: .infinity))
		]
	}

	var body: some View {
		ScrollView(.vertical) {
			Grid(alignment: .leadingFirstTextBaseline) {
				Divider()
				GridRow {
					ForEach(Self.header, id: \.self) { header in
						Text(header)
							.font(.headline)
					}
				}
				Divider()
				ForEach(Self.allServices, id: \.self) { serviceInfos in
					GridRow {
						ForEach(0..<serviceInfos.count, id: \.self) { index in
							let serviceInfo = serviceInfos[index]
							Text(serviceInfo)
								.font(.subheadline)
								.gridColumnAlignment(index == 0 ? .leading : .center)
						}
					}
					Divider()
				}
			}
			.padding()
		}
		.toolbar {
			DoneToolbar(placement: .topBarTrailing) {
				router.dismiss()
			}
		}
		.navigationTitle(L10n.info)
	}
}

#Preview {
	NavigationView {
		InfoView()
			.environment(Router())
	}
}
