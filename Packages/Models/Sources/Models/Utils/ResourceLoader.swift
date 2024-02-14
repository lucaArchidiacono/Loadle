//
//  ResourceLoader.swift
//  Loadle
//
//  Created by Luca Archidiacono on 13.02.2024.
//

import Foundation

final class ResourceLoader {
	enum Resource {
		struct InternalResource {
			let name: String
			let fileExtension: String

			fileprivate init(name: String, fileExtension: String) {
				self.name = name
				self.fileExtension = fileExtension
			}
		}

		static let jengaSkitMP3 = InternalResource(name: "JengaInstructionsSkit", fileExtension: "mp3")
	}

	static func load(resource: Resource.InternalResource) -> Data {
		let url = Bundle.module.url(forResource: resource.name, withExtension: resource.fileExtension)
		do {
			guard let url else {
				fatalError("Was not able to build URL for \(resource.name).\(resource.fileExtension)")
			}
			return try Data(contentsOf: url)
		} catch {
			fatalError("Please fix the resource loading!")
		}
	}
	
	static func load(resource: Resource.InternalResource) -> URL {
		let url = Bundle.module.url(forResource: resource.name, withExtension: resource.fileExtension)
		guard let url else {
			fatalError("Was not able to build URL for \(resource.name).\(resource.fileExtension)")
		}
		return url
	}
}
