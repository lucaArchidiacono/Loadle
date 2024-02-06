//
//  FileCache.swift
//
//
//  Created by Luca Archidiacono on 24.01.2024.
//

import Foundation

/// File cache implementation that can read and write any `Codable` content and uses file coordinator to coordinate I/O.
public struct FileCache<Content: Codable>: FileCacheProtocol {
  public let fileURL: URL

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public func read() throws -> Content {
    let fileCoordinator = NSFileCoordinator(filePresenter: nil)

    return try fileCoordinator.coordinate(readingItemAt: fileURL, options: [.withoutChanges]) { fileURL in
      try JSONDecoder().decode(Content.self, from: Data(contentsOf: fileURL))
    }
  }

  public func write(_ content: Content) throws {
    let fileCoordinator = NSFileCoordinator(filePresenter: nil)

    try fileCoordinator.coordinate(writingItemAt: fileURL, options: [.forReplacing]) { fileURL in
      try JSONEncoder().encode(content).write(to: fileURL)
    }
  }
}

/// Protocol describing file cache that's able to read and write serializable content.
public protocol FileCacheProtocol<Content> {
  associatedtype Content: Codable

  func read() throws -> Content
  func write(_ content: Content) throws
}
