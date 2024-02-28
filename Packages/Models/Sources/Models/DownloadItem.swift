//
//  DownloadItem.swift
//  Loadle
//
//  Created by Luca Archidiacono on 13.02.2024.
//

import Foundation
import LinkPresentation
import SwiftUI

public struct DownloadItem: Identifiable, Codable {
    public enum State: Codable, Equatable {
        case pending
        case progress(currentBytes: Double, totalBytes: Double)
        case completed
        case cancelled
        case failed
    }

    public let id: UUID
    public let remoteURL: URL
    public let streamURL: URL
    public let state: State
	public let metadata: LPLinkMetadata
	public let service: MediaService

	enum CodingKeys: CodingKey {
		case id
		case remoteURL
		case streamURL
		case state
		case service
		case metadata
	}

	public init(remoteURL: URL, streamURL: URL, service: MediaService, metadata: LPLinkMetadata) {
		self.id = UUID()
		self.state = .pending
        self.remoteURL = remoteURL
		self.service = service
		self.streamURL = streamURL
		self.metadata = metadata
    }

	public init(id: UUID, remoteURL: URL, streamURL: URL, service: MediaService, state: State, metadata: LPLinkMetadata) {
        self.id = id
        self.state = state
        self.remoteURL = remoteURL
		self.streamURL = streamURL
		self.service = service
		self.metadata = metadata
    }

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decode(UUID.self, forKey: .id)
		self.remoteURL = try container.decode(URL.self, forKey: .remoteURL)
		self.streamURL = try container.decode(URL.self, forKey: .streamURL)
		self.state = try container.decode(State.self, forKey: .state)
		self.service = try container.decode(MediaService.self, forKey: .service)

		let metadata = try container.decode(Data.self, forKey: .metadata)
		self.metadata = try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: metadata)!
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(remoteURL, forKey: .remoteURL)
		try container.encode(streamURL, forKey: .streamURL)
		try container.encode(state, forKey: .state)
		try container.encode(service, forKey: .service)

		let encodedMetadata = try NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
		try container.encode(encodedMetadata, forKey: .metadata)
	}

    public func update(state: State) -> Self {
        return Self(id: id,
					remoteURL: remoteURL, 
					streamURL: streamURL,
					service: service,
                    state: state,
					metadata: metadata)
    }
}
