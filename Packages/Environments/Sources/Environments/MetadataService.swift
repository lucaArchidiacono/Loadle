//
//  MetadataService.swift
//  
//
//  Created by Luca Archidiacono on 26.02.2024.
//

import Foundation
import Logger
import LinkPresentation

@Observable
@MainActor
public final class MetadataService {
	public enum Error: Swift.Error, CustomStringConvertible {
		case noMetadataAvailable(url: URL)

		public var description: String {
			let description = "\(type(of: self))."
			switch self {
			case let .noMetadataAvailable(url):
				return description + "noMetadataAvailable: " + "No metadata is available for the following url: \(url)"
			}
		}
	}
	public static let shared = MetadataService()

	private init() {}

	nonisolated
	public func fetch(using url: URL, onComplete: @escaping (Result<LPLinkMetadata, Swift.Error>) -> Void) {
		let provider = LPMetadataProvider()

		provider.startFetchingMetadata(for: url) { metadata, error in
			if let error {
				log(.error, "Fetching metadata for \(url) resulted into: \(error)")
				onComplete(.failure(error))
				return
			}

			guard let metadata else {
				onComplete(.failure(Error.noMetadataAvailable(url: url)))
				return
			}

			log(.debug, "Fetched metadata successfully: \(metadata)")
			onComplete(.success(metadata))
		}
	}
}

