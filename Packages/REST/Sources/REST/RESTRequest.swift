//
//  RESTRequest.swift
//
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation

public extension REST {
    struct HTTPRequest: Identifiable, CustomDebugStringConvertible {
        public let id: UUID = .init()

        private var urlComponents = URLComponents()
        private var options = [ObjectIdentifier: Any]()

        public var method: HTTPMethod = .get
        public var headers: [AnyHashable: String] = [:]
        public var body: HTTPBody = EmptyBody()

        public var scheme: String { urlComponents.scheme ?? "https" }

        public var host: String? {
            get { urlComponents.host }
            set { urlComponents.host = newValue }
        }

        public var path: String {
            get { urlComponents.path }
            set { urlComponents.path = newValue }
        }

        var queryItems: [URLQueryItem]? {
            get { urlComponents.queryItems }
            set { urlComponents.queryItems = newValue }
        }

        var url: URL? { urlComponents.url }

        public init(host: String, path: String, method: HTTPMethod, headers: [AnyHashable: String] = [:], body: HTTPBody = EmptyBody()) {
            urlComponents.scheme = "https"
            self.host = host
            self.path = path
            self.method = method
            self.headers = headers
            self.body = body
        }

		public var debugDescription: String {
			let debugString = """
			HTTP Request: { ID -> \(id); URL -> \(urlComponents); OPTIONS -> \(options); METHOD -> \(method); HEADERS -> \(headers);  BODY -> \(body); }
			"""
			return debugString
		}
    }
}
