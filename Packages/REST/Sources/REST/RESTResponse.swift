//
//  RESTResponse.swift
//
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation

public extension REST {
	struct HTTPResponse: CustomDebugStringConvertible {
        public let request: HTTPRequest
        private let response: HTTPURLResponse
        private let body: Data

        init(request: HTTPRequest, response: HTTPURLResponse, body: Data) {
            self.request = request
            self.response = response
            self.body = body
        }

        public var message: String { HTTPURLResponse.localizedString(forStatusCode: response.statusCode) }
        public var headers: [AnyHashable: Any] { response.allHeaderFields }
		public var data: Data { body }

		public func decode<T: Decodable>() throws -> T { try JSONDecoder().decode(T.self, from: body) }

		public var debugDescription: String {
			let body: Any = String(data: body, encoding: .utf8) ?? (try? JSONSerialization.jsonObject(with: body)) ?? "<unavailable>"
			let debugString = """
			HTTP Response: {
			\tRequest: {
			\t\t\(request)
			\t},
			\tStatus: {
			\t\t\(response.statusCode) \(message)
			\t},
			\tHeaders: {
			\t\t\(headers)
			\t},
			\tBody: {
			\t\t\(body)
			\t}
			}
			"""
			return debugString
		}
    }
}
