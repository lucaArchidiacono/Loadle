//
//  MetaDataTransformer.swift
//
//
//  Created by Luca Archidiacono on 26.02.2024.
//

import Foundation
import LinkPresentation

@objc(LPLinkMetadataTransformer)
public final class LPLinkMetadataTransformer: ValueTransformer {
	public override class func transformedValueClass() -> AnyClass {
		return LPLinkMetadata.self
	}

	public override class func allowsReverseTransformation() -> Bool {
		return true
	}

	public override func transformedValue(_ value: Any?) -> Any? {
		guard let metadata = value as? LPLinkMetadata else { return nil }

		do {
			let data = try NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
			return data
		} catch {
			assertionFailure("Failed to transform `LPLinkMetadata` to `Data`")
			return nil
		}
	}

	public override func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let data = value as? NSData else { return nil }

		do {
			let metadata = try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data as Data)
			return metadata
		} catch {
			assertionFailure("Failed to transform `Data` to `LPLinkMetadata`")
			return nil
		}
	}
}

extension LPLinkMetadataTransformer {
	static let name = NSValueTransformerName(rawValue: String(describing: LPLinkMetadataTransformer.self))

	static func register() {
		let transformer = LPLinkMetadataTransformer()
		ValueTransformer.setValueTransformer(transformer, forName: name)
	}
}
