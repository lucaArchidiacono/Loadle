//
//  NSFileCoordinator+.swift
//
//
//  Created by Luca Archidiacono on 24.01.2024.
//

import Foundation

public extension NSFileCoordinator {
    func coordinate<R>(
        readingItemAt itemURL: URL,
        options: ReadingOptions = [],
        accessor: (URL) throws -> R
    ) throws -> R {
        var error: NSError?
        var result: Result<R, Error> = .failure(CocoaError(.fileReadUnknown))

        coordinate(readingItemAt: itemURL, options: options, error: &error) { url in
            result = Result { try accessor(url) }
        }

        if let error {
            throw error
        }

        return try result.get()
    }

    func coordinate(
        writingItemAt itemURL: URL,
        options: WritingOptions = [],
        accessor: (URL) throws -> Void
    ) throws {
        var error: NSError?
        var accessorError: Error?

        coordinate(writingItemAt: itemURL, options: options, error: &error) { url in
            do {
                try accessor(url)
            } catch {
                accessorError = error
            }
        }

        if let e = error ?? accessorError {
            throw e
        }
    }
}
