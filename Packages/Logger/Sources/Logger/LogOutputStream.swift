//
//  LogOutputStream.swift
//
//
//  Created by Luca Archidiacono on 23.01.2024.
//

import Foundation
import OSLog

final class LogOutputStream: OutputStream {
  var nextOutputStream: OutputStream?

  private let logger: Logger

  init() {
    logger = Logger()
  }

  func write(level: LogLevel, _ message: String) {
    let logLevel = transform(level)

    logger.log(level: logLevel, "\(message)")

    nextOutputStream?.write(level: level, message)
  }

  func fetch(completion: @escaping ([Data]) -> Void) {
    nextOutputStream?.fetch(completion: completion)
  }

  func getLogFiles(completion: @escaping ([URL]) -> Void) {
    nextOutputStream?.getLogFiles(completion: completion)
  }

  private func transform(_ level: LogLevel) -> OSLogType {
    switch level {
    case .verbose: return .default
    case .debug: return .debug
    case .error: return .fault
    case .warning: return .error
    case .info: return .info
    }
  }
}
