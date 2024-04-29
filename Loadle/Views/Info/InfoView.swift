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
		L10n.image
	]

	private static var services = [
		["Bilibili.com & Bilibili.tv", "✅", "✅", "✅", "➖"],
		["Instagram Posts & Stories", "✅", "✅", "✅", "➖"],
		["Instagram Reels", "✅", "✅", "✅", "➖"],
		["OK Video", "✅", "❌", "❌", "✅"],
		["Pinterest", "✅", "✅", "✅", "➖"],
		["Reddit", "✅", "✅", "✅", "❌"],
		["Rutube", "✅", "✅", "✅", "✅"],
		["Soundcloud", "➖", "✅", "➖", "✅"],
		["Streamable", "✅", "✅", "✅", "➖"],
		["Tiktok", "✅", "✅", "✅", "❌"],
		["Tumblr", "✅", "✅", "✅", "➖"],
		["Twitch Clips", "✅", "✅", "✅", "✅"],
		["Twitter/X", "✅", "✅", "✅", "➖"],
		["Vimeo", "✅", "✅", "✅", "✅"],
		["Vine Archive", "✅", "✅", "✅", "➖"],
		["VK Videos & Clips", "✅", "❌", "❌", "✅"],
		["Youtube Videos, Shorts & Music", "✅", "✅", "✅", "✅"]
	]

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
				ForEach(Self.services, id: \.self) { serviceInfos in
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
