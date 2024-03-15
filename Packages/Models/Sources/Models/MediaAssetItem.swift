//
//  MediaAssetItem.swift
//
//
//  Created by Luca Archidiacono on 16.02.2024.
//

import Foundation
import LinkPresentation

public struct MediaAssetItem: Hashable, Identifiable, Codable {
	public var id: URL { remoteURL }
	public let remoteURL: URL
    public let fileURLs: [URL]
    public let service: MediaService
	public let metadata: LPLinkMetadata
	public let createdAt: Date
	public let title: String

	enum CodingKeys: CodingKey {
		case remoteURL
		case fileURLs
		case service
		case createdAt
		case metadata
		case title
	}

	public init(remoteURL: URL, fileURLs: [URL], service: MediaService, metadata: LPLinkMetadata, createdAt: Date, title: String) {
		self.remoteURL = remoteURL
		self.fileURLs = fileURLs
		self.service = service
		self.metadata = metadata
		self.createdAt = createdAt
		self.title = title
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.remoteURL = try container.decode(URL.self, forKey: .remoteURL)
		self.fileURLs = try container.decode([URL].self, forKey: .fileURLs)
		self.service = try container.decode(MediaService.self, forKey: .service)

		let metadata = try container.decode(Data.self, forKey: .metadata)
		self.metadata = try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: metadata)!

		self.createdAt = try container.decode(Date.self, forKey: .createdAt)
		self.title = try container.decode(String.self, forKey: .title)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(remoteURL, forKey: .remoteURL)
		try container.encode(fileURLs, forKey: .fileURLs)
		try container.encode(service, forKey: .service)

		let encodedMetadata = try NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
		try container.encode(encodedMetadata, forKey: .metadata)

		try container.encode(createdAt, forKey: .createdAt)
		try container.encode(title, forKey: .title)
	}

	public func configure(fileURLs: [URL]) -> Self {
		Self.init(remoteURL: remoteURL,
				  fileURLs: fileURLs,
				  service: service,
				  metadata: metadata,
				  createdAt: createdAt,
				  title: title)
	}
}
