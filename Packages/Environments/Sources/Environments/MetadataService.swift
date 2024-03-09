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
		let provider = LPMetadataProvider()
		return try await provider.startFetchingMetadata(for: url)
	}
}

