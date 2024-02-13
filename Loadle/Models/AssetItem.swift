//
//  AssetItem.swift
//  Loadle
//
//  Created by Luca Archidiacono on 08.02.2024.
//

import Foundation
import SwiftUI

struct AssetItem: Identifiable {
	let id: UUID
	let fileURL: URL
	
	var title: String { fileURL.lastPathComponent }
	var image: Image { 
		if fileURL.containsMovie {
			return Asset.movieIcon.swiftUIImage
		} else if fileURL.containsAudio {
			return Asset.audioIcon.swiftUIImage
		}
		return Image(systemName: "arrow.down.to.line.circle")
	}

	init(fileURL: URL) {
		self.id = UUID()
		self.fileURL = fileURL
	}
}

extension AssetItem {
	static var previews: AssetItem {
		return AssetItem(fileURL: ResourceLoader.load(resource: ResourceLoader.Resource.jengaSkitMP3))
	}
}
