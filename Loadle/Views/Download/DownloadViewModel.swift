//
//  DownloadViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import Logger
import SwiftUI
import Environments
import Models
import Generator

@MainActor
@Observable
final class DownloadViewModel {
	public var loadedAssets: [AssetItem] = []
	public var errorDetails: ErrorDetails?

	public var isLoading: Bool = false
	public var audioOnly: Bool = false

	private let downloadService: DownloadService = DownloadService.shared

	init() {}

	func startDownload(using url: String, preferences: UserPreferences, router: Router) {
		guard !isLoading else { return }
		isLoading = true

		downloadService.downloadMedia(using: url, preferences: preferences, audioOnly: audioOnly) { [weak self] result in
			guard let self else { return }
			self.isLoading = false

			if case let .failure(error) = result {
				log(.error, error)
				buildErrorDetails(error, router: router)
			}
		}
	}
}

extension DownloadViewModel {
	private func buildErrorDetails(_ error: Error, router: Router) {
		if let error = error as? DownloadService.ServiceError {
			switch error {
			case .noValidURL:
				errorDetails = ErrorDetails(
					title: L10n.invalidUrlTitle,
					description: L10n.invalidUrlWrongDescription,
					actions: [.primary(title: L10n.ok)])
			case .noRedirectURL:
				errorDetails = buildGenericErrorDetails(using: error, router: router)
			}
		} else {
			errorDetails = buildGenericErrorDetails(using: error, router: router)
		}
	}

	private func buildGenericErrorDetails(using error: Error, router: Router) -> ErrorDetails {
		var actions: [ErrorDetails.Action] = []
		if MailComposerView.canSendEmail() {
			actions.append(.primary(title: L10n.sendEmail) {
				Logging.shared.getLogFiles { urls in
					let attachements: [EmailData.AttachmentData] = urls
						.compactMap { url in
							guard let data = try? Data(contentsOf: url) else { return nil }
							return EmailData.AttachmentData(data: data, mimeType: url.mimeType(), fileName: url.lastPathComponent)
						}
					router.presented = .mail(
						emailData: .init(subject: L10n.sendEmailSubject(UUID()),
										 body: .raw(body: L10n.sendEmailDescription(error)),
										 attachments: attachements),
						onComplete: { [weak self] result in
							switch result {
							case .success(let mailResult):
								log(.info, mailResult)
							case .failure(let error):
								log(.error, error)
								self?.errorDetails = nil
								self?.errorDetails = ErrorDetails(
									title: L10n.sendEmailFailedTitle,
									description: L10n.sendEmailFailedDescription,
									actions: [.primary(title: L10n.ok)])
							}
						})
				}
			})
			actions.append(.secondary(title: L10n.cancel))
		} else {
			actions.append(.primary(title: L10n.ok))
		}
		return ErrorDetails(
			title: L10n.somethingWentWrongTitle,
			description: L10n.somethingWentWrongDescription,
			actions: actions)
	}
}
