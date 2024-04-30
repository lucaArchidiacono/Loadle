//
//  SettingsViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 21.02.2024.
//

import Foundation
import Generator
import Logger
import Models

@MainActor
@Observable
final class SettingsViewModel {
    #if DEBUG
        var logStreams: [String] = []
    #endif

    @ObservationIgnored
    private var observationTask: Task<Void, Never>?

    init() {
        #if DEBUG
            observationTask = Task { [weak self] in
                let oldLogs = await Logging.shared.fetch()
                self?.logStreams = oldLogs

                for await log in Logging.shared.stream {
                    if oldLogs.isEmpty {
                        self?.logStreams.append(log)
                    } else if let lastLog = self?.logStreams.last, lastLog != log {
                        self?.logStreams.append(log)
                    }
                }
            }
        #endif
    }

    func loadLogFiles() async -> EmailData {
        let urls = await Logging.shared.getLogFiles()
        let attachements: [EmailData.AttachmentData] = urls
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return EmailData.AttachmentData(data: data, mimeType: url.mimeType(), fileName: url.lastPathComponent)
            }
        return EmailData(subject: L10n.sendLogFileEmailSubject, body: .raw(body: L10n.sendLogFileEmailDescription), attachments: attachements)
    }
}
