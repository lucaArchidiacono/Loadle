//
//  RESTTransformer.swift
//
//
//  Created by Luca Archidiacono on 06.02.2024.
//

import Foundation

extension REST {
    static func transform(_ request: REST.HTTPRequest) throws -> URLRequest {
        guard let url = request.url else {
            // we couldn't construct a proper URL out of the request's URLComponents
            throw REST.HTTPError(code: .invalidRequest, request: request, response: nil, underlyingError: nil)
        }

        // construct the URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        // copy over any custom HTTP headers
        for (header, value) in request.headers {
            urlRequest.addValue(value, forHTTPHeaderField: "\(header)")
        }

        if !request.body.isEmpty {
            // if our body defines additional headers, add them
            for (header, value) in request.body.additionalHeaders {
                urlRequest.addValue(value, forHTTPHeaderField: header)
            }

            // attempt to retrieve the body data
            do {
                urlRequest.httpBodyStream = try request.body.encode()
                return urlRequest
            } catch {
                // something went wrong creating the body; stop and report back
                throw REST.HTTPError(code: .invalidRequest, request: request, response: nil, underlyingError: nil)
            }
        }
        return urlRequest
    }
}
