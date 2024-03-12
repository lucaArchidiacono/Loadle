//
//  MediaServiceViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 28.02.2024.
//

import Foundation
import Models
import Environments
import AVFoundation
import Logger

@Observable
@MainActor
final class MediaServiceViewModel {
	public let mediaService: MediaService
	public var mediaAssetItems = [MediaAssetItem]()

	init(mediaService: MediaService) {
		self.mediaService = mediaService
	}

	public func fetch() async {
		self.mediaAssetItems = await MediaAssetService.shared.loadAllAssets(for: mediaService)
	}
}
