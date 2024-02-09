//
//  EmailData.swift
//  Loadle
//
//  Created by Luca Archidiacono on 09.02.2024.
//

import Foundation

struct EmailData: Identifiable {
	let id: UUID = UUID()
	let subject: String
	let body: Body
	var attachments = [AttachmentData]()

	enum Body {
		case html(body: String)
		case raw(body: String)
	}

	struct AttachmentData {
		let data: Data
		let mimeType: String
		let fileName: String
	}
}
