//
//  DownloadViewModel.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Environments
import Foundation
import Generator
import Logger
import Models
import SwiftUI

@MainActor
@Observable
final class DownloadViewModel {
    public var errorDetails: ErrorDetails?

    public var isLoading: Bool = false
    public var audioOnly: Bool = false

    private let downloadService: DownloadService = .shared

    init() {}

    func startDownload(using url: String, preferences: UserPreferences, router: Router) {
        guard let url = URL(string: url), UIApplication.shared.canOpenURL(url) else {
            errorDetails = ErrorDetails(
                title: L10n.invalidUrlTitle,
                description: L10n.invalidUrlWrongDescription,
                actions: [.primary(title: L10n.ok)]
            )
            return
        }

        guard !isLoading else { return }
        isLoading = true
        downloadService.download(using: url, preferences: preferences, audioOnly: audioOnly) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success:
                log(.info, "Successfully downloaded!")
            case let .failure(error):
                errorDetails = buildGenericErrorDetails(using: error, router: router)
            }
        }
    }
}

extension DownloadViewModel {
    private func buildGenericErrorDetails(using _: Error, router _: Router) -> ErrorDetails {
        return ErrorDetails(
            title: L10n.somethingWentWrongTitle,
            description: L10n.somethingWentWrongDescription,
            actions: [.primary(title: L10n.ok)]
        )
    }
}
