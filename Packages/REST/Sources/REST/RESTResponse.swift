//
//  RESTResponse.swift
//
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation

extension REST {
	public struct HTTPResponse {
		public let request: HTTPRequest
		private let response: HTTPURLResponse
		public let body: Data?

		init(request: HTTPRequest, response: HTTPURLResponse, body: Data?) {
			self.request = request
			self.response = response
			self.body = body
		}

		public var status: HTTPStatus {
			HTTPStatus(rawValue: response.statusCode)
		}

		public var message: String {
			HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
		}

		public var headers: [AnyHashable: Any] { response.allHeaderFields }
	}
}
