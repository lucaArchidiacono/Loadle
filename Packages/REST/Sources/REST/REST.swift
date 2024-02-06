//
//  REST.swift
//
//
//  Created by Luca Archidiacono on 04.02.2024.
//

public enum REST {
    /// HTTP method
    public struct HTTPMethod: Hashable, RawRepresentable {
        public static let get = HTTPMethod(rawValue: "GET")
        public static let post = HTTPMethod(rawValue: "POST")
        public static let delete = HTTPMethod(rawValue: "DELETE")
        public static let put = HTTPMethod(rawValue: "PUT")

        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue.uppercased()
        }
    }

    public struct HTTPStatus: Hashable, RawRepresentable {
        static let notModified = HTTPStatus(rawValue: 304)
        static let badRequest = HTTPStatus(rawValue: 400)
        static let notFound = HTTPStatus(rawValue: 404)

        static func isSuccess(_ code: Int) -> Bool {
            (200 ..< 300).contains(code)
        }

        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        var isSuccess: Bool {
            Self.isSuccess(rawValue)
        }
    }

    /// HTTP headers
    enum HTTPHeader {
        static let host = "Host"
        static let authorization = "Authorization"
        static let contentType = "Content-Type"
        static let etag = "ETag"
        static let ifNoneMatch = "If-None-Match"
        static let userAgent = "User-Agent"
    }
}
