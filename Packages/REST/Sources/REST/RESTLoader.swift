//
//  RESTLoader.swift
//
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation
import Logger

public extension REST {
    final class Loader: NSObject {
        private let session = URLSession.shared

        public static let shared = Loader()

        public func load(using request: REST.HTTPRequest) async throws -> REST.HTTPResponse {
            let urlRequest = try REST.transform(request)

            var data: Data!
            var urlResponse: URLResponse!

            do {
                let tuple = try await session.data(for: urlRequest)
                data = tuple.0
                urlResponse = tuple.1
            } catch {
                throw REST.HTTPError(code: .unknown, request: request, response: nil, underlyingError: error)
            }

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                throw REST.HTTPError(code: .invalidResponse, request: request, response: nil, underlyingError: nil)
            }

            let status = REST.HTTPStatus(rawValue: httpResponse.statusCode)

            let response = REST.HTTPResponse(request: request, response: httpResponse, body: data)

            if status.isSuccess {
                return response
            } else {
                let code = HTTPStatusCode(fromRawValue: status.rawValue)
                throw REST.HTTPError(code: .badHTTPStatusCode(code: code), request: request, response: response, underlyingError: nil)
            }
        }
    }
}
