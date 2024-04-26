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
		self.observationTask = Task { [weak self] in
			for await log in Logging.logStream {
				self?.logStreams.append(log)
			}
		}
		#endif
	}

	deinit {
		observationTask?.cancel()
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
