//
//  DownloadView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import Logger
import SwiftUI

struct DownloadView: View {
	@EnvironmentObject private var preferences: UserPreferences
	@EnvironmentObject private var theme: Theme

	@Environment(Router.self) private var router: Router

	@State private var url: String = ""
	@State private var errorDetails: ErrorDetails? = nil

	@State private var viewModel = DownloadViewModel()

	init() {
		UITextField.appearance().clearButtonMode = .whileEditing
	}

	var body: some View {
		ZStack {
			downloadView
			errorView
		}
		.toolbar {
			SettingsToolbar {
				router.presented = .settings
			}
		}
		.navigationBarTitle(L10n.appTitle)
		.background(theme.primaryBackgroundColor)
	}

	@ViewBuilder
	var downloadView: some View {
		ScrollView {
			VStack {
				Spacer()
				HStack {
					Image(systemName: "link")
					TextField(L10n.pasteLink, text: $url)
				}
				.padding()
				.background(theme.secondaryBackgroundColor)
				.cornerRadius(8)
				.padding(.horizontal)
				.padding(.vertical, 10)
				.foregroundColor(theme.tintColor)

				Button {
					viewModel.startDownload(using: url, preferences: preferences) { result in
						if case .failure(let error) = result {
							buildErrorDetails(error)
						}
					}
				} label: {
					Text(L10n.downloadButtonTitle)
						.frame(maxWidth: .infinity)
						.padding(.horizontal)
						.padding(.vertical, 10)
				}
				.buttonStyle(.borderedProminent)
				.padding(.horizontal)
				.padding(.bottom, 10)

				Toggle(isOn: $viewModel.audioOnly) {
					Text(L10n.downloadAudioOnly)
				}
				.toggleStyle(iOSCheckboxToggleStyle())
				.padding(.bottom, 10)

				ForEach(viewModel.loadingEvents, id: \.id) { event in
					let view = DownloadTaskSectionView(
						title: event.title,
						image: event.image,
						state: event.state,
						onPause: {
							viewModel.pauseDownload(event: event)
						},
						onResume: {
							viewModel.resumeDownload(event: event)
						})
						.swipeActions(edge: .trailing) {
							Button(role: .destructive,
								   action: { viewModel.delete(event: event) } ,
								   label: { Image(systemName: "trash") } )
						}
					if let fileURL = event.fileURL {
						view
							.padding()
							.frame(maxWidth: .infinity)
							.background(Color(.systemBackground))
							.cornerRadius(12)
							.padding()
							.contextMenu {
								ShareLink(item: fileURL)
							}
					} else {
						view
							.padding()
							.frame(maxWidth: .infinity)
							.background(Color(.systemBackground))
							.cornerRadius(12)
							.padding()
					}
				}
//				.scrollContentBackground(.hidden)
			}
		}
		.scrollDismissesKeyboard(.immediately)
	}

	@ViewBuilder
	private var errorView: some View {
		ErrorView(errorDetails: $errorDetails)
	}

	private func buildErrorDetails(_ error: Error) {
		if let error = error as? DownloadViewModelError {
			switch error {
			case .noValidURL:
				errorDetails = ErrorDetails(
					title: L10n.invalidUrlTitle,
					description: L10n.invalidUrlWrongDescription,
					actions: [.primary(title: L10n.ok)])
			case .noRedirectURL:
				errorDetails = buildGenericErrorDetails(using: error)
			}
		} else {
			errorDetails = buildGenericErrorDetails(using: error)
		}
	}

	private func buildGenericErrorDetails(using error: Error) -> ErrorDetails {
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
						onComplete: { result in
							switch result {
							case .success(let mailResult):
								log(.info, mailResult)
							case .failure(let error):
								log(.error, error)
								errorDetails = nil
								errorDetails = ErrorDetails(
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

#Preview {
	DownloadView()
		.environmentObject(Theme.shared)
		.environmentObject(UserPreferences.shared)
}
