//
//  FileOutputStream.swift
//
//
//  Created by Luca Archidiacono on 23.01.2024.
//

import Foundation
import OSLog

final class FileOutputStream: OutputStream {
    private let queue = DispatchQueue(label: "io.lucaa.Loadle.FileLogOutputStream", qos: .utility)

    private var currentFileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss_SSS"
        return formatter
    }()

    private var logDir: URL
    private var logFile: URL

    var nextOutputStream: OutputStream?

    init?() {
        do {
            let documentsDir = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let logDir = documentsDir.appending(path: "LOGS")
            self.logDir = logDir

            if !FileManager.default.fileExists(atPath: logDir.path()) {
                try FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
            }

            let logFile = logDir
                .appendingPathComponent(currentFileDateFormatter.string(from: Date()))
                .appendingPathExtension("txt")
            self.logFile = logFile

            setup()
        } catch {
            os_log(.error, "\(error)")
            return nil
        }
    }

    private func setup() {
        deleteOutdatedLogFiles()
        createNewLogFile()
    }

    private func createNewLogFile() {
        if !FileManager.default.fileExists(atPath: logFile.path()) {
            FileManager.default.createFile(atPath: logFile.path(), contents: nil, attributes: nil)
        }
    }

    /// Deletes outdated log files which are more then 1 month old.
    private func deleteOutdatedLogFiles() {
        let calendar = Calendar.current
        let currentDate = Date()

        do {
            let urls = try _getLogFiles()

            let removeableURLs: [URL] = urls.filter { url in
                guard let logDate = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate else { return false }

                let components = calendar.dateComponents([.month], from: logDate, to: currentDate)
                guard let month = components.month, month >= 1 else {
                    // Is less then one month old
                    return false
                }

                // Is more then one month old
                return true
            }

            // Delete the log files
            for url in removeableURLs {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            os_log(.error, "\(error)")
        }
    }

    func write(level: LogLevel, _ message: String) {
        queue.async {
            self._write(message)
        }

        nextOutputStream?.write(level: level, message)
    }

    private func _write(_ message: String) {
        guard let data = message.appending("\n").data(using: .utf8),
              let fileHandle = try? FileHandle(forWritingTo: logFile) else { return }

        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
        try? fileHandle.close()
    }

    func fetch(completion: @escaping ([String]) -> Void) {
        queue.async {
            do {
                let fileLogOutputStreamString = try self._fetch()
				completion(fileLogOutputStreamString)
            } catch {
                os_log(.error, "\(error)")
                completion([])
            }
        }
    }

    private func _fetch() throws -> [String] {
        let fileHandle = try FileHandle(forReadingFrom: logFile)
        let data = fileHandle.readDataToEndOfFile()
        try fileHandle.close()
		return (String(data: data, encoding: .utf8) ?? "")
			.components(separatedBy: "\n")
			.dropLast()
    }

    func getLogFiles(completion: @escaping (([URL]) -> Void)) {
        queue.async {
            do {
                let fileLogOutputStreamFiles = try self._getLogFiles()
                if let nextOutputStream = self.nextOutputStream {
                    nextOutputStream.getLogFiles { outputStreamFiles in
                        var outputStreamFiles = outputStreamFiles
                        outputStreamFiles.append(contentsOf: fileLogOutputStreamFiles)
                        completion(outputStreamFiles)
                    }
                } else {
                    completion(fileLogOutputStreamFiles)
                }
            } catch {
                os_log(.error, "\(error)")
                completion([])
            }
        }
    }

    private func _getLogFiles() throws -> [URL] {
        let files = try FileManager.default.contentsOfDirectory(at: logDir, includingPropertiesForKeys: [.nameKey, .isDirectoryKey], options: .skipsHiddenFiles)

        let sortedFiles: [URL] = files
            .map { url in
                (url, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
            }
            .sorted(by: { $0.1 < $1.1 })
            .map { $0.0 }

        return sortedFiles
    }
}
