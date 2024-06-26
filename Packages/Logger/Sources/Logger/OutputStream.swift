//
//  OutputStream.swift
//
//
//  Created by Luca Archidiacono on 23.01.2024.
//

import Foundation

protocol OutputStream: AnyObject {
    @discardableResult
    func setNext(outputStream: OutputStream) -> OutputStream

    /// Logs a message with a specified log level.
    ///
    /// - Parameters:
    ///   - level: The log level (e.g., verbose, debug, info, warning, error).
    ///   - message: The message to log.
    func write(level: LogLevel, _ message: String)

    /// Returns a list of all files which are used as logs.
    func getLogFiles(completion: @escaping ([URL]) -> Void)

    var nextOutputStream: OutputStream? { get set }
}

extension OutputStream {
    func setNext(outputStream: OutputStream) -> OutputStream {
        nextOutputStream = outputStream
        return outputStream
    }
}
