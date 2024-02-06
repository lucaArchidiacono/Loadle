//
//  RESTResponse.swift
//
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation

extension REST {
	public struct HTTPResponse<T> {
		public let request: HTTPRequest
		private let response: HTTPURLResponse
		public let body: T

		init(request: HTTPRequest, response: HTTPURLResponse, body: T) {
			self.request = request
			self.response = response
			self.body = body
		}

		public var message: String {
			HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
		}

		public var headers: [AnyHashable: Any] { response.allHeaderFields }
	}
}
