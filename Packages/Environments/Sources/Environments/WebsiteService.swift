//
//  WebsiteService.swift
//
//
//  Created by Luca Archidiacono on 15.02.2024.
//

import Foundation
import WebKit

final class WebsiteService: NSObject {
	enum ServiceError: Error {
		case noImageData
	}

	enum Representation {
		case pdf(Result<Data, Error>)
		case snapshot(Result<Data, Error>)
		case archive(Result<Data, Error>)

		var size: Int {
			switch self {
			case .archive(let result),
				 .snapshot(let result),
				 .pdf(let result):
				switch result {
				case .success(let data): return data.count
				case .failure: return 0
				}
			}
		}
	}

	private var store: [URL: WebViewWrapper] = [:]

	public static let shared = WebsiteService()

	private override init() {}

	public func download(url: URL, completionHandler: @escaping (Result<Array<Representation>, Error>) -> Void) {
		let webViewWrapper = WebViewWrapper()
		
		webViewWrapper.load(url: url) { [weak self] result in
			completionHandler(result)
			self?.store[url] = nil
		}

		store[url] = webViewWrapper
	}
}

extension WebsiteService {
	class WebViewWrapper: NSObject, WKNavigationDelegate {
		private lazy var webView: WKWebView = {
			let webView = WKWebView()
			webView.navigationDelegate = self
			return webView
		}()

		private var onComplete: ((Result<Array<Representation>, Error>) -> Void)?

		func load(url: URL, onComplete: @escaping (Result<Array<Representation>, Error>) -> Void) {
			self.onComplete = onComplete
			webView.load(.init(url: url))
		}

		func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
			let group = DispatchGroup()
			var representations: Array<Representation> = []

			let config = WKSnapshotConfiguration()
			config.rect = .init(origin: .zero, size: webView.scrollView.contentSize)

			/// Snapshot of Website - PNG Image
			group.enter()
			webView.takeSnapshot(with: config) { image, error in
				defer { group.leave() }

				if let error = error {
					representations.append(.snapshot(.failure(error)))
					return
				}
				guard let pngData = image?.pngData() else {
					representations.append(.snapshot(.failure(ServiceError.noImageData)))
					return
				}
				representations.append(.snapshot(.success(pngData)))
			}

			/// PDF of Website
			group.enter()
			webView.createPDF { result in
				defer { group.leave() }
				representations.append(.pdf(result))
			}

			/// Webarchive of Website
			group.enter()
			webView.createWebArchiveData { result in
				defer { group.leave() }
				representations.append(.archive(result))
			}

			group.notify(queue: .main) { [weak self] in
				self?.onComplete?(.success(representations))
			}
		}

		func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
			onComplete?(.failure(error))
		}
	}
}
