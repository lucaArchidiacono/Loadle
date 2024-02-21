//
//  WebsiteService.swift
//
//
//  Created by Luca Archidiacono on 15.02.2024.
//

import Foundation
import Logger
import Models
import WebKit

@MainActor
final class WebsiteService: NSObject {
    private var store: [URL: WebViewWrapper] = [:]

    public static let shared = WebsiteService()

    override private init() {}

    public func download(url: URL, completionHandler: @escaping (Result<[WebsiteRepresentation], Error>) -> Void) {
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

        private var onComplete: ((Result<[WebsiteRepresentation], Error>) -> Void)?

        func load(url: URL, onComplete: @escaping (Result<[WebsiteRepresentation], Error>) -> Void) {
            self.onComplete = onComplete
            DispatchQueue.main.async {
                self.webView.load(.init(url: url))
            }
        }

        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            let group = DispatchGroup()
            var representations: [WebsiteRepresentation] = []

            let config = WKSnapshotConfiguration()
            config.rect = .init(origin: .zero, size: webView.scrollView.contentSize)

            /// Snapshot of Website - PNG Image
            group.enter()
            webView.takeSnapshot(with: config) { image, error in
                defer { group.leave() }

                if let error = error {
                    log(.error, error)
                    return
                }
                guard let pngData = image?.pngData() else { return }
                representations.append(.snapshot(pngData))
            }

            /// PDF of Website
            group.enter()
            webView.createPDF { result in
                defer { group.leave() }
                switch result {
                case let .success(data): representations.append(.pdf(data))
                case let .failure(error): log(.error, error)
                }
            }

            /// Webarchive of Website
            group.enter()
            webView.createWebArchiveData { result in
                defer { group.leave() }
                switch result {
                case let .success(data): representations.append(.archive(data))
                case let .failure(error): log(.error, error)
                }
            }

            group.notify(queue: .main) { [weak self] in
                self?.onComplete?(.success(representations))
            }
        }

        func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
            onComplete?(.failure(error))
        }
    }
}
