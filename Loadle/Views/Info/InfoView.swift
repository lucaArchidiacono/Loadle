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
	private static var header = ["Service", "Video/Audio", "Audio", "Video", "Metadata"]

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
		}
	}
}

#Preview {
	InfoView()
}
