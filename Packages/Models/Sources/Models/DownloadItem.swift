//
//  DownloadItem.swift
//  Loadle
//
//  Created by Luca Archidiacono on 13.02.2024.
//

import Foundation
import SwiftUI
import LinkPresentation

public struct DownloadItem: Identifiable, Codable {
	public enum State: Codable, Equatable {
		case pending
		case progress(currentBytes: Double, totalBytes: Double)
		case completed
		case cancelled
		case failed
	}

	public struct MediaInformation: Codable {
		public let mediaService: MediaService
		public let cobaltRequest: CobaltRequest

		public init(mediaService: MediaService, cobaltRequest: CobaltRequest) {
			self.mediaService = mediaService
			self.cobaltRequest = cobaltRequest
		}
	}

	public let id: UUID
	public let remoteURL: URL
	public let state: State
	public let mediaInformation: MediaInformation?
	public let metaData: LPLinkMetadata
	public let websiteRepresentations: [WebsiteRepresentation]
	public let onComplete: ((Result<Void, Error>) -> Void)?

	public var title: String {
		metaData.title ?? remoteURL.absoluteString
	}

	public enum CodingKeys: String, CodingKey {
		case id
		case metaData
		case remoteURL
		case state
		case mediaDownloadInformation
		case websiteRepresentations
	}

	public init(remoteURL: URL, metaData: LPLinkMetadata, websiteRepresentations: [WebsiteRepresentation], onComplete: ((Result<Void, Error>) -> Void)?) {
		self.id = UUID()
		self.state = .pending
		self.remoteURL = remoteURL
		self.metaData = metaData
		self.mediaInformation = nil
		self.onComplete = onComplete
		self.websiteRepresentations = websiteRepresentations
	}

	private init(id: UUID, remoteURL: URL, metaData: LPLinkMetadata, state: State, mediaInformation: MediaInformation?, websiteRepresentations: [WebsiteRepresentation], onComplete: ((Result<Void, Error>) -> Void)?) {
		self.id = id
		self.state = state
		self.remoteURL = remoteURL
		self.metaData = metaData
		self.mediaInformation = mediaInformation
		self.onComplete = onComplete
		self.websiteRepresentations = websiteRepresentations
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decode(UUID.self, forKey: .id)
		let metaData = try container.decode(Data.self, forKey: .metaData)
		self.metaData = try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: metaData)!
		self.remoteURL = try container.decode(URL.self, forKey: .remoteURL)
		self.state = try container.decode(State.self, forKey: .state)
		self.mediaInformation = try container.decodeIfPresent(MediaInformation.self, forKey: .mediaDownloadInformation)
		self.websiteRepresentations = try container.decode(Array<WebsiteRepresentation>.self, forKey: .websiteRepresentations)
		self.onComplete = nil
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.id, forKey: .id)
		let encodedMetadata = try NSKeyedArchiver.archivedData(withRootObject: self.metaData, requiringSecureCoding: true)
		try container.encode(encodedMetadata, forKey: .metaData)
		try container.encode(self.remoteURL, forKey: .remoteURL)
		try container.encode(self.state, forKey: .state)
		try container.encodeIfPresent(self.mediaInformation, forKey: .mediaDownloadInformation)
		try container.encode(self.websiteRepresentations, forKey: .websiteRepresentations)
	}

	public func update(state: State) -> Self {
		return Self.init(id: self.id,
						 remoteURL: self.remoteURL,
						 metaData: self.metaData,
						 state: state,
						 mediaInformation: self.mediaInformation,
						 websiteRepresentations: self.websiteRepresentations,
						 onComplete: self.onComplete)
	}

	public func update(mediaInformation: MediaInformation) -> Self {
		return Self.init(id: self.id,
						 remoteURL: self.remoteURL,
						 metaData: self.metaData,
						 state: self.state,
						 mediaInformation: mediaInformation,
						 websiteRepresentations: self.websiteRepresentations,
						 onComplete: self.onComplete)
	}

	public func update(onComplete: @escaping (Result<Void, Error>) -> Void) -> Self {
		let initialOnComplete = self.onComplete

		return Self.init(
			id: self.id,
			remoteURL: self.remoteURL,
			metaData: self.metaData,
			state: self.state,
			mediaInformation: self.mediaInformation,
			websiteRepresentations: self.websiteRepresentations) { result in
				initialOnComplete?(result)
				onComplete(result)
			}
	}
}
