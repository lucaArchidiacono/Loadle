//
//  AssetItemSectionView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 13.02.2024.
//

import Foundation
import Models
import Environments
import SwiftUI

struct AssetItemSectionView: View {
	@EnvironmentObject private var theme: Theme
	
	let title: String
	let image: Image
	let fileURL: URL

	var body: some View {
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
		.applyTheme(theme)
		.contextMenu {
			ShareLink(item: fileURL)
		}
	}
}

#Preview {
	List {
		Section {
			AssetItemSectionView(title: AssetItem.previews.title,
								 image: AssetItem.previews.image,
								 fileURL: AssetItem.previews.fileURL)
		}
		.listRowBackground(Theme.shared.secondaryBackgroundColor)
	}
	.environmentObject(Theme.shared)
}
