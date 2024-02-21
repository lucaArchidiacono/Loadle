//
//  SettingsViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 21.02.2024.
//

import Foundation
import Logger
import Models
import Generator

@MainActor
@Observable
final class SettingsViewModel {
	func loadLogFiles(onComplete: @escaping (EmailData) -> Void) {
		Logging.shared.getLogFiles { urls in
			let attachements: [EmailData.AttachmentData] = urls
				.compactMap { url in
					guard let data = try? Data(contentsOf: url) else { return nil }
					return EmailData.AttachmentData(data: data, mimeType: url.mimeType(), fileName: url.lastPathComponent)
				}
			let emailData = EmailData(subject: L10n.sendLogFileEmailSubject, body: .raw(body: L10n.sendLogFileEmailDescription), attachments: attachements)
			onComplete(emailData)
		}
	}
}
