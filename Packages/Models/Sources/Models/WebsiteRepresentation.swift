//
//  WebsiteRepresentation.swift
//
//
//  Created by Luca Archidiacono on 20.02.2024.
//

import Foundation

public enum WebsiteRepresentation: Codable {
	case pdf(Data)
	case snapshot(Data)
	case archive(Data)
}
