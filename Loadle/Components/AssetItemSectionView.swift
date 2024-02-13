//
//  AssetItemSectionView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 13.02.2024.
//

import Foundation
import SwiftUI

struct AssetItemSectionView: View {
	@EnvironmentObject private var theme: Theme
	
	let title: String
	let image: Image
	let fileURL: URL

	var body: some View {
//		Section {
			VStack(alignment: .leading) {
				HStack {
					image
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 40, height: 40)
					Text(title)
						.font(.headline)
				}
			}
//		}
		.contextMenu {
			ShareLink(item: fileURL)
		}
		.applyTheme(theme)
	}
}

#Preview {
	AssetItemSectionView(title: AssetItem.previews.title,
					 image: AssetItem.previews.image,
					 fileURL: AssetItem.previews.fileURL)
	.environmentObject(Theme.shared)
}
