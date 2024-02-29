//
//  URLTransformer.swift
//
//
//  Created by Luca Archidiacono on 29.02.2024.
//

import Foundation
import Models

extension DataTransformer {
	enum URL {}
}


extension DataTransformer.URL {
	static func transform(_ url: URL, service: MediaService) -> URL {
		switch service {
		case .tiktok:
			// Specify the list of query parameters to keep in the final URL
			let allowedParams = ["_d", "_r", "checksum"]

			// Get the components of the original URL
			if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
				// Filter and keep only the allowed query parameters
				components.queryItems = components.queryItems?.filter { item in
					allowedParams.contains(item.name)
				}

				// Create the transformed URL with the filtered query parameters
				if let transformedURL = components.url {
					return transformedURL
				}
			}
			return url
		case .youtube: return url
		case .instagram: return url
		case .twitter: return url
		case .reddit: return url
		case .twitch: return url
		case .pinterest: return url
		case .bilibili: return url
		case .soundcloud: return url
		case .okVideo: return url
		case .rutube: return url
		case .streamable: return url
		case .tumblr: return url
		case .vimeo: return url
		case .vine: return url
		case .vkVideos: return url
		}
	}
}
