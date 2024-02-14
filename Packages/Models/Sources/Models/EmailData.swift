//
//  EmailData.swift
//  Loadle
//
//  Created by Luca Archidiacono on 09.02.2024.
//

import Foundation

public struct EmailData: Identifiable {
	public let id: UUID = UUID()
	public let subject: String
	public let body: Body
	public let attachments: [AttachmentData]

	public init(subject: String, body: Body, attachments: [AttachmentData]) {
		self.subject = subject
		self.body = body
		self.attachments = attachments
	}

	public enum Body {
		case html(body: String)
		case raw(body: String)
	}

	public struct AttachmentData {
		public let data: Data
		public let mimeType: String
		public let fileName: String
		
		public init(data: Data, mimeType: String, fileName: String) {
			self.data = data
			self.mimeType = mimeType
			self.fileName = fileName
		}
	}
}
