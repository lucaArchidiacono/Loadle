//
//  Destination.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import Models

enum Destination: Identifiable, Hashable {
	case downloads
	case media(service: MediaService)

	var id: String {
		switch self {
		case .downloads:
			return "downloads"
		case .media(let service):
			return service.id
		}
	}
}
