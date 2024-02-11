//
//  Destination.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation

enum Destination: Identifiable, Hashable {
	case downloads
	case service(service: Service)

	var id: String {
		switch self {
		case .downloads:
			return "downloads"
		case .service(let service):
			return service.id
		}
	}
}
