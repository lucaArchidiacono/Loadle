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
					title: "Hmm...",
					description: "It seems like your URL is not valid. Please check for invalid characters.",
					actions: [
						.primary(title: "Ok") {
							errorDetails = nil
						}
					])
			case .noRedirectURL:
				errorDetails = buildGenericErrorDetails()
			}
		} else {
			errorDetails = buildGenericErrorDetails()
		}
	}

	private func buildGenericErrorDetails() -> ErrorDetails {
		var actions: [ErrorDetails.Action] = []
		if MailComposerView.canSendEmail() {
			actions.append(.primary(title: "Send Email") {
				router.presented = .mail(
					emailData: .init(subject: "",
									 body: .raw(body: "I'd like to take the chance and thank you for using my app!\nWith this email you are trying to file a bug. Please state your issue below this line:\n"),
									 attachments: []),
					onComplete: { result in
						switch result {
						case .success(let mailResult):
							log(.info, mailResult)
						case .failure(let error):
							log(.error, error)
							errorDetails = nil
							errorDetails = ErrorDetails(
								title: "Dang! Was not able to send an email.",
								description: "It seems like something went wrong and you were not able to send the bug report via email!",
								actions: [.primary(title: "Ok", { errorDetails = nil })])
						}
					})
			})
		} else {
			actions.append(.primary(title: "Ok", { errorDetails = nil }))
		}
		return ErrorDetails(
			title: "Uh-oh",
			description: "Something went wrong. Retry again and if the error still persists, you can either contact me or file a bug report.",
			actions: actions)
	}
}

#Preview {
	ContentView()
		.environment(DownloadManager.shared)
		.environmentObject(Theme.shared)
		.environmentObject(UserPreferences.shared)
}
