//
//  Sequence+.swift
//
//
//  Created by Luca Archidiacono on 22.03.2024.
//

import Foundation

public extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }

    func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            guard let transformed = try await transform(element) else { continue }
            values.append(transformed)
        }

        return values
    }
}
