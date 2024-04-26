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
