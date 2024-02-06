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

		public func load(using request: REST.HTTPRequest, onComplete: @escaping (Result<REST.HTTPResponse<Data>, REST.HTTPError<Data>>) -> Void) {
			let result: Result<URLRequest, REST.HTTPError<Data>> = REST.transform(request)
			switch result {
			case .success(let urlRequest):
				let dataTask = session.dataTask(with: urlRequest) { (data, response, error) in
					if let error = error {
						onComplete(.failure(REST.HTTPError(code: .unknown, request: request, response: nil, underlyingError: error)))
						return
					}
					guard let urlResponse = response as? HTTPURLResponse else {
						onComplete(.failure(REST.HTTPError(code: .invalidResponse, request: request, response: nil, underlyingError: nil)))
						return
					}

					let status = REST.HTTPStatus(rawValue: urlResponse.statusCode)

					if let data = data {
						let response = REST.HTTPResponse(request: request, response: urlResponse, body: data)

						if status.isSuccess {
							onComplete(.success(response))
							return
						} else {
							let code = HTTPStatusCode(fromRawValue: status.rawValue)
							onComplete(.failure(REST.HTTPError(code: .badHTTPStatusCode(code: code), request: request, response: response, underlyingError: error)))
							return
						}
					} else {
						if status.isSuccess {
							onComplete(.failure(REST.HTTPError(code: .noDataFound, request: request, response: nil, underlyingError: error)))
							return
						} else {
							let code = HTTPStatusCode(fromRawValue: status.rawValue)
							onComplete(.failure(REST.HTTPError(code: .badHTTPStatusCode(code: code), request: request, response: nil, underlyingError: error)))
							return
						}
					}
				}

				dataTask.resume()
			case .failure(let error):
				onComplete(.failure(error))
			}
		}

		public func load<T: Decodable>(using request: REST.HTTPRequest, onComplete: @escaping (Result<REST.HTTPResponse<T>, REST.HTTPError<T>>) -> Void) {
			let result: Result<URLRequest, REST.HTTPError<T>> = REST.transform(request)
			switch result {
			case .success(let urlRequest):
				let dataTask = session.dataTask(with: urlRequest) { (data, response, error) in
					if let error = error {
						onComplete(.failure(REST.HTTPError(code: .unknown, request: request, response: nil, underlyingError: error)))
						return
					}
					guard let urlResponse = response as? HTTPURLResponse else {
						onComplete(.failure(REST.HTTPError(code: .invalidResponse, request: request, response: nil, underlyingError: nil)))
						return
					}

					let status = REST.HTTPStatus(rawValue: urlResponse.statusCode)

					if let data = data {
						do {
							let decoded = try JSONDecoder().decode(T.self, from: data)

							let response = REST.HTTPResponse(request: request, response: urlResponse, body: decoded)

							if status.isSuccess {
								onComplete(.success(response))
								return
							} else {
								let code = HTTPStatusCode(fromRawValue: status.rawValue)
								onComplete(.failure(REST.HTTPError(code: .badHTTPStatusCode(code: code), request: request, response: response, underlyingError: error)))
								return
							}
						} catch {
							onComplete(.failure(REST.HTTPError(code: .invalidDecode, request: request, response: nil, underlyingError: error)))
							return
						}
					} else {
						if status.isSuccess {
							onComplete(.failure(REST.HTTPError(code: .noDataFound, request: request, response: nil, underlyingError: error)))
							return
						} else {
							let code = HTTPStatusCode(fromRawValue: status.rawValue)
							onComplete(.failure(REST.HTTPError(code: .badHTTPStatusCode(code: code), request: request, response: nil, underlyingError: error)))
							return
						}
					}
				}

				dataTask.resume()
			case .failure(let error):
				onComplete(.failure(error))
			}
		}
	}
}
