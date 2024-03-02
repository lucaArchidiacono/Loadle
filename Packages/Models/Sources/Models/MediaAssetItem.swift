//
//  MediaAssetItem.swift
//
//
//  Created by Luca Archidiacono on 16.02.2024.
//

import Foundation
import LinkPresentation

public struct MediaAssetItem: Identifiable, Codable {
	public let id: UUID
	public let remoteURL: URL
    public let fileURL: URL
    public let service: MediaService
	public let metadata: LPLinkMetadata
	public let createdAt: Date

	enum CodingKeys: CodingKey {
		case id
		case remoteURL
		case fileURL
		case service
		case createdAt
		case metadata
	}

	public init(id: UUID, remoteURL: URL, fileURL: URL, service: MediaService, metadata: LPLinkMetadata, createdAt: Date) {
		self.id = id
		self.remoteURL = remoteURL
		self.fileURL = fileURL
		self.service = service
		self.metadata = metadata
		self.createdAt = createdAt
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decode(UUID.self, forKey: .id)
		self.remoteURL = try container.decode(URL.self, forKey: .remoteURL)
		self.fileURL = try container.decode(URL.self, forKey: .fileURL)
		self.service = try container.decode(MediaService.self, forKey: .service)

		let metadata = try container.decode(Data.self, forKey: .metadata)
		self.metadata = try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: metadata)!

		self.createdAt = try container.decode(Date.self, forKey: .createdAt)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(remoteURL, forKey: .remoteURL)
		try container.encode(fileURL, forKey: .fileURL)
		try container.encode(service, forKey: .service)

		let encodedMetadata = try NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
		try container.encode(encodedMetadata, forKey: .metadata)

		try container.encode(createdAt, forKey: .createdAt)
	}

	public func configure(fileURL: URL) -> Self {
		Self.init(id: id,
				  remoteURL: remoteURL,
				  fileURL: fileURL,
				  service: service,
				  metadata: metadata,
				  createdAt: createdAt)
	}
}
