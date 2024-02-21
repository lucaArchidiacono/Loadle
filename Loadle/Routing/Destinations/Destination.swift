//
//  Destination.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import Models

enum Destination: Identifiable, Hashable {
    case media(service: MediaService)

    var id: String {
        switch self {
        case let .media(service):
            return service.id
        }
    }
}
