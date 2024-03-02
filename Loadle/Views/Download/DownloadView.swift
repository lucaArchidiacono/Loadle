//
//  DownloadView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Environments
import Foundation
import Generator
import Logger
import SwiftUI

struct DownloadView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

	@EnvironmentObject private var preferences: UserPreferences
//    @EnvironmentObject private var theme: Theme

    @Environment(Router.self) private var router: Router

    @State private var url: String = ""
    @FocusState private var isFocused: Bool

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
			DoneToolbar(placement: .topBarTrailing) {
                dismiss()
			}
        }
//        .applyTheme(theme)
        .navigationBarTitle(L10n.download)
    }

    @ViewBuilder
    var downloadView: some View {
        List {
            downloadSection
            downloadItemsSection
            //			assetItemsSection
        }
//        .background(theme.primaryBackgroundColor)
        .scrollDismissesKeyboard(.immediately)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var downloadSection: some View {
        Section {
            HStack {
                Image(systemName: "link")
                TextField(L10n.pasteLink, text: $url)
                    .focused($isFocused)
            }
            .padding()
			.background(Color.secondaryBackground)
            .cornerRadius(8)
//            .foregroundColor(theme.tintColor)

            Button {
                viewModel.startDownload(using: url, preferences: preferences, router: router)
                isFocused = false
            } label: {
                Text(L10n.downloadButtonTitle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)

            HStack {
                Spacer()
                Toggle(isOn: $viewModel.audioOnly) {
                    Text(L10n.downloadAudioOnly)
                }
                .toggleStyle(iOSCheckboxToggleStyle())
                Spacer()
            }
        }
        .listRowSeparator(.hidden)
//        .listRowBackground(theme.secondaryBackgroundColor)
    }

    @ViewBuilder
    private var downloadItemsSection: some View {
        Section {
			ForEach(viewModel.downloads, id: \.id) { download in
                DownloadItemSectionView(
					title: download.metadata.title ?? download.remoteURL.absoluteString,
                    state: download.state,
					iconProvider: download.metadata.iconProvider,
                    onCancel: {
						viewModel.cancel(item: download)
                    },
                    onResume: {
						viewModel.resume(item: download)
                    }
                )
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive,
                           action: { viewModel.delete(item: download) },
                           label: { Image(systemName: "trash") })
                }
            }
        }
//        .listRowBackground(theme.secondaryBackgroundColor)
    }

    @ViewBuilder
    private var errorView: some View {
        ErrorView(errorDetails: $viewModel.errorDetails)
    }
}

#Preview {
    DownloadView()
//        .environmentObject(Theme.shared)
        .environmentObject(UserPreferences.shared)
        .environment(Router())
}
