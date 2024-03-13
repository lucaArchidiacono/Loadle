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

struct MediaAssetItemSectionView: View {
	@State private var duration: String?

	let mediaAssetItem: MediaAssetItem
	let onTap: () -> Void

	var body: some View {
		Section {
			VStack(alignment: .leading) {
				HStack(alignment: .top) {
					AsyncImageProvider(itemProvider: mediaAssetItem.metadata.iconProvider, placeholder: Image(systemName: "bookmark.fill")) { image in
						image
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 20)
					}
					
					Text(mediaAssetItem.metadata.title!)
						.lineLimit(2)
						.truncationMode(.tail)

					Spacer()
					if let imageProvider = mediaAssetItem.metadata.imageProvider {
						AsyncImageProvider(itemProvider: imageProvider, placeholder: Image(uiImage: UIImage())) { image in
							image
								.resizable()
								.aspectRatio(contentMode: .fill)
								.frame(width: 80, height: 80)
								.clipShape(RoundedRectangle(cornerRadius: 8))
						}
					}
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
						Text("•")
						if let duration {
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
			let asset = AVURLAsset(url: mediaAssetItem.fileURL.absoluteURL)

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
		.onTapGesture {
			onTap()
		}
	}
}
