//
//  HTTPBody.swift
//  
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation

public protocol HTTPBody {
	var isEmpty: Bool { get }
	var additionalHeaders: [String: String] { get }
	func encode() throws -> InputStream
}

extension HTTPBody {
	public var isEmpty: Bool { return false }
	public var additionalHeaders: [String: String] { return [:] }
}

extension REST {
	public struct EmptyBody: HTTPBody {
		public let isEmpty: Bool = true

		public init() { }
		public func encode() throws -> InputStream { InputStream(data: Data()) }
	}

	public struct DataBody: HTTPBody {
		private let data: Data

		public var isEmpty: Bool { data.isEmpty }
		public var additionalHeaders: [String : String]

		public init(_ data: Data, additionalHeaders: [String : String] = [:]) {
			self.data = data
			self.additionalHeaders = additionalHeaders
		}

		public func encode() throws -> InputStream { InputStream(data: data) }
	}

	public struct JSONBody: HTTPBody {
		public let isEmpty: Bool = false
		public var additionalHeaders: [String : String] = [
			"Accept": "application/json",
			"Content-Type": "application/json"
		]

		private let _encode: () throws -> Data

		public init<T: Encodable>(_ value: T, encoder: JSONEncoder = JSONEncoder()) {
			self._encode = { try encoder.encode(value) }
		}

		public func encode() throws -> InputStream {
			let data = try _encode()
			return InputStream(data: data)
		}
	}

	public struct FormBody: HTTPBody {
		public var isEmpty: Bool { values.isEmpty }
		public let additionalHeaders = [
			"Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
		]

		private let values: [URLQueryItem]

		public init(_ values: [URLQueryItem]) {
			self.values = values
		}

		public init(_ values: [String: String]) {
			let queryItems = values.map { URLQueryItem(name: $0.key, value: $0.value) }
			self.init(queryItems)
		}

		public func encode() throws -> InputStream {
			let pieces = values.map(self.urlEncode)
			let bodyString = pieces.joined(separator: "&")
			return InputStream(data: Data(bodyString.utf8))
		}

		private func urlEncode(_ queryItem: URLQueryItem) -> String {
			let name = urlEncode(queryItem.name)
			let value = urlEncode(queryItem.value ?? "")
			return "\(name)=\(value)"
		}

		private func urlEncode(_ string: String) -> String {
			return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
		}
	}
}
