//
//  DownloadManager.swift
//  Loadle
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation
import REST
import Logger

final class DownloadManager: Observable {
	@Published var downloads: [REST.DownloadTask] = []

	private static var host = "co.wuk.sh"

	private let downloader: REST.Downloader
	private let loader: REST.Loader = REST.Loader()

	init(downloader: REST.Downloader) {
		self.downloader = downloader

		downloader.allTasks.forEach { downloadTask in
			downloads.append(downloadTask)
		}
	}

	func startDownload(using url: URL, preferences: UserPreferences) {
//		let jsonBody: REST.JSONBody = REST.JSONBody(<#T##value: Encodable##Encodable#>)
		let request = REST.HTTPRequest(host: Self.host, path: "/api/json", method: .post, body: REST.EmptyBody())
		loader.load(using: request) { [weak self] result in
			guard let self else { return }
			// TODO: Luca Archidiacono - Build new get request to download the files.
			switch result {
			case .success(let response):
				print(response)
			case .failure(let error):
				log(.error, error)
			}
		}
	}


	func load(using url: URL) {
		let request = REST.HTTPRequest(host: Self.host, path: "/api/json", method: .post, body: REST.EmptyBody())
		loader.load(using: request) { [weak self] result in
			guard let self else { return }
			// TODO: Luca Archidiacono - Build new get request to download the files.
			switch result {
			case .success(let response):
				download(using: <#T##URL#>)
			case .failure(let error):
				log(.error, error)
			}
		}
	}

	func download(using url: URL) {
		let request = REST.HTTPRequest(host: Self.host, path: "/api/json", method: .post, body: REST.EmptyBody())
		downloader.startDownload(using: request) { result in
			switch result {
			case .success(let downloadTask):
				self.downloads.append(downloadTask)
			case .failure(let error):
				log(.error, error)
			}
		}
	}
}
