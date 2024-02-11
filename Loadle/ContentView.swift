//
//  ContentView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import Logger
import SwiftUI

struct ContentView: View {
	@Environment(DownloadManager.self) private var downloadManager
	@EnvironmentObject private var preferences: UserPreferences
	@EnvironmentObject private var theme: Theme

	@State private var router: Router = Router()
	@State private var url: String = ""
	@State private var audioOnly: Bool = false
	@State private var isLoading: Bool = false
	@State private var errorDetails: ErrorDetails? = nil

	init() {
		UITextField.appearance().clearButtonMode = .whileEditing
	}

	var body: some View {
		NavigationStack(path: $router.path) {
			ZStack {
				downloadView
				errorView
			}
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						router.presented = .settings
					} label: {
						Image(systemName: "gear")
					}
				}
			}
			.navigationBarTitle(L10n.appTitle)
			.background(theme.primaryBackgroundColor)
		}
		.applyTheme(theme)
		.withSheetDestinations(destination: $router.presented)
		.withCoverDestinations(destination: $router.covered)
    }

	@ViewBuilder
	var downloadView: some View {
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
				guard !isLoading else { return }
				isLoading = true
				downloadManager.startDownload(using: url, preferences: preferences, audioOnly: audioOnly) { result in
					if case .failure(let error) = result {
						buildErrorDetails(error)
					}
					isLoading = false
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

			Toggle(isOn: $audioOnly) {
				Text(L10n.downloadAudioOnly)
			}
			.toggleStyle(iOSCheckboxToggleStyle())
			.padding(.bottom, 10)

			List(downloadManager.loadingEvents, id: \.id) { event in
				let view = DownloadTaskSectionView(
					title: event.title,
					image: event.image,
					state: event.state,
					onPause: {
						downloadManager.pauseDownload(for: event)
					},
					onResume: {
						downloadManager.resumeDownload(for: event)
					})
					.swipeActions(edge: .trailing) {
						Button(role: .destructive,
							   action: { downloadManager.delete(for: event) } ,
							   label: { Image(systemName: "trash") } )
					}
				if let fileURL = event.fileURL {
					view
						.contextMenu {
							ShareLink(item: fileURL)
						}
				} else {
					view
				}
			}
			.scrollContentBackground(.hidden)
		}
	}

	@ViewBuilder
	private var errorView: some View {
		ErrorView(errorDetails: $errorDetails)
	}

	private func buildErrorDetails(_ error: Error) {
		if let error = error as? DownloadManagerError {
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
	ContentView()
		.environment(DownloadManager.shared)
		.environmentObject(Theme.shared)
		.environmentObject(UserPreferences.shared)
}
