//
//  MediaAssetItemSectionView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 12.03.2024.
//

import Foundation
import Models
import Fundamentals
import AVFoundation
import Logger
import SwiftUI
import NukeUI

struct MediaAssetItemSectionView: View {
	@State private var duration: String?

	let mediaAssetItem: MediaAssetItem
	let onTap: () -> Void

	var body: some View {
		Section {
			VStack(alignment: .leading) {
				HStack(alignment: .top) {
					LazyImage(url: URL(string: FavIcon(mediaAssetItem.service.domain)[.m]),
							  transaction: Transaction(animation: .smooth)) { phase in
						Group {
							if let image = phase.image {
								image.resizable()
							} else if phase.error != nil {
								Image(systemName: "bookmark.fill")
									.resizable()
							} else {
								Rectangle()
									.fill(.clear)
							}
						}
						.scaledToFit()
						.frame(width: 20, height: 20)
					}

					Spacer()

					Text(mediaAssetItem.title.trimmingCharacters(in: .whitespaces))
						.lineLimit(2)
						.truncationMode(.tail)

					Spacer()
					
					Group {
						if let artwork = mediaAssetItem.artwork, let uiImage = UIImage(data: artwork) {
							Image(uiImage: uiImage)
								.resizable()
								.aspectRatio(contentMode: .fill)
						} else {
							Rectangle()
						}
					}
					.frame(width: 80, height: 80)
					.clipShape(RoundedRectangle(cornerRadius: 8))
				}
				HStack(alignment: .top) {
					Group {
						if let host = mediaAssetItem.remoteURL.host(percentEncoded: false) {
							Text(host.hasPrefix("www.") ? String(host.dropFirst(4)) : host)
								.lineLimit(1)
								.truncationMode(.tail)
						} else {
							Text(mediaAssetItem.remoteURL.absoluteString)
								.lineLimit(1)
								.truncationMode(.tail)
						}
						if let duration {
							Text("•")
							Text(duration)
						}
					}
					.font(.footnote)
					Spacer()
				}
				Spacer()
			}
		}
		.frame(height: 100)
		.task {
			guard let url = mediaAssetItem.fileURLs.first?.absoluteURL else { return }
			let asset = AVURLAsset(url: url)

			do {
				let assetDuration = try await asset.load(.duration)
				let formatter = DateComponentsFormatter()
				formatter.unitsStyle = .positional
				formatter.zeroFormattingBehavior = .pad
				formatter.allowedUnits = [.hour, .minute, .second]


				guard let formattedString = formatter.string(from: assetDuration.seconds) else { return }
				self.duration = formattedString
			} catch {
				log(.error, error)
			}
		}
		.contentShape(Rectangle())
//		.onTapGesture {
//			onTap()
//		}
	}
}
