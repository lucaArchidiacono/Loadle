//
//  MetadataService.swift
//  
//
//  Created by Luca Archidiacono on 26.02.2024.
//

import Foundation
import Logger
import LinkPresentation

public final class MetadataService {
	public static let shared = MetadataService()

	private init() {}

	public func fetch(using url: URL) async throws -> LPLinkMetadata {
		log(.info, "🏁 Start fetching LPLinkMetadata using: \(url)")
		let provider = LPMetadataProvider()
		let result = try await provider.startFetchingMetadata(for: url)
		log(.info, "✅ Finished fetching LPLinkMetadata with following result: \(result)")
		return result
	}
}

