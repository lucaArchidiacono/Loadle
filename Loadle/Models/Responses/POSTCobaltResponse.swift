//
//  POSTCobaltResponse.swift
//  Loadle
//
//  Created by Luca Archidiacono on 06.02.2024.
//

import Foundation

struct POSTCobaltResponse: Decodable {
	let status: POSTCobaltStatusResponse
	let text: String?
	let url: URL?
	let pickerType: String?
	let picker: [POSTCobaltPickerItemResponse]
	let audio: String?

	enum CodingKeys: CodingKey {
		case status
		case text
		case url
		case pickerType
		case picker
		case audio
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.status = try container.decode(POSTCobaltResponse.POSTCobaltStatusResponse.self, forKey: .status)
		self.text = try container.decodeIfPresent(String.self, forKey: .text)
		self.url = try container.decodeIfPresent(URL.self, forKey: .url)
		self.pickerType = try container.decodeIfPresent(String.self, forKey: .pickerType)
		self.picker = try container.decodeIfPresent([POSTCobaltResponse.POSTCobaltPickerItemResponse].self, forKey: .picker) ?? []
		self.audio = try container.decodeIfPresent(String.self, forKey: .audio)
	}

	enum POSTCobaltStatusResponse: String, Decodable {
		case error
		case redirect
		case stream
		case success
		case rateLimit
		case picker

		enum CodingKeys: String, CodingKey {
			case error
			case redirect
			case stream
			case success
			case rateLimit = "rate-limit"
			case picker
		}
	}

	struct POSTCobaltPickerItemResponse: Decodable {
		let type: String
		let url: URL
		let thumb: String
	}
}
