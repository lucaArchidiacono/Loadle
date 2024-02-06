//
//  RESTLoader.swift
//
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation

extension REST {
	final public class Loader: NSObject {
		private let 	session = URLSession.shared

		public func load(using request: REST.HTTPRequest, onComplete: @escaping (Result<REST.HTTPResponse, Error>) -> Void) {
			guard let url = request.url else {
				// we couldn't construct a proper URL out of the request's URLComponents
				onComplete(.failure(REST.HTTPError(code: .invalidRequest, request: request, response: nil, underlyingError: nil)))
				return
			}

			// construct the URLRequest
			var urlRequest = URLRequest(url: url)
			urlRequest.httpMethod = request.method.rawValue

			// copy over any custom HTTP headers
			for (header, value) in request.headers {
				urlRequest.addValue(value, forHTTPHeaderField: "\(header)")
			}

			if request.body.isEmpty == false {
				// if our body defines additional headers, add them
				for (header, value) in request.body.additionalHeaders {
					urlRequest.addValue(value, forHTTPHeaderField: header)
				}

				// attempt to retrieve the body data
				do {
					urlRequest.httpBodyStream = try request.body.encode()
				} catch {
					// something went wrong creating the body; stop and report back
					onComplete(.failure(REST.HTTPError(code: .invalidRequest, request: request, response: nil, underlyingError: nil)))
					return
				}
			}

			let dataTask = session.dataTask(with: urlRequest) { (data, response, error) in
				guard let error = error else {
					onComplete(.failure(REST.HTTPError(code: .unknown, request: request, response: nil, underlyingError: error)))
					return
				}
				guard let urlResponse = response as? HTTPURLResponse else {
					onComplete(.failure(REST.HTTPError(code: .invalidResponse, request: request, response: nil, underlyingError: nil)))
					return
				}

				let response = REST.HTTPResponse(request: request, response: urlResponse, body: data)

				if response.status.isSuccess {
					onComplete(.success(response))
					return
				} else {
					let code = HTTPStatusCode(fromRawValue: response.status.rawValue)
					onComplete(.failure(REST.HTTPError(code: .badHTTPStatusCode(code: code), request: request, response: response, underlyingError: nil)))
					return
				}
			}
		}
	}
}
