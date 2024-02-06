//
//  Logging.swift
//
//
//  Created by Luca Archidiacono on 22.01.2024.
//
import OSLog

public enum LogLevel: Int {
    /// Use this to provide detailed debugging information
    case verbose

    /// Never use this in productive code! Only in debugging sessions
    case debug

    /// Use this to provide general information on what the app is doing with what data
    case info

    /// Use this to describe a runtime warning
    case warning

    /// Use this to describe a runtime error
    case error

    func toSymbol() -> String {
        switch self {
        case .verbose:
            return "💬"
        case .debug:
            return "⭕️"
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "🔥"
        }
    }
}

struct Logging {
    private var currentQueueName: String = {
        let name = __dispatch_queue_get_label(nil)
        return String(cString: name, encoding: .utf8) ?? "n.a."
    }()

    private struct RegistryKey: Hashable {
        let subsystem: String
        let category: String
    }

    private let outputStream: OutputStream
    static let shared: Logging = .init()

    private init() {
        outputStream = LogOutputStream()

        if let fileOutputStream = FileOutputStream() {
            outputStream.setNext(outputStream: fileOutputStream)
        }
    }

    /// Get a list of all log files as `[URL]`.
    public func getLogFiles(completion: @escaping ([URL]) -> Void) {
        outputStream.getLogFiles(completion: completion)
    }

    /// Get the data of the current log file.
    func fetch(completion: @escaping ([Data]) -> Void) {
        outputStream.fetch(completion: completion)
    }

    func log(_ level: LogLevel, _ message: Any..., file: String, line: Int, function: String) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let location = "\(fileName).\(trimFunctionName(function)):\(line)"
        let message = message.map { String(describing: $0) }.joined(separator: " ")
        let logString = "\(Date()) \(level.toSymbol()) \(currentQueueName) \(location) \(message)"

        outputStream.write(level: level, logString)
    }

    /// Trims the input function name by removing any content after the first "(".
    /// - Parameter function: The function name to be trimmed.
    /// - Returns: The trimmed function name.
    private func trimFunctionName(_ function: String) -> String {
        return String(function.split(separator: "(", maxSplits: 1, omittingEmptySubsequences: true)[0])
    }
}
