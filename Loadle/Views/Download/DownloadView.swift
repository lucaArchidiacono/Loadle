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
        .navigationBarTitle(L10n.download)
    }

    @ViewBuilder
    var downloadView: some View {
        List {
            downloadSection
            downloadItemsSection
        }
		#if !os(visionOS)
        .scrollDismissesKeyboard(.immediately)
		#endif
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
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)

            Button {
				viewModel.startDownload(using: url)
                isFocused = false
            } label: {
				Group {
					if viewModel.isLoading {
						ProgressView()
					} else {
						Text(L10n.downloadButtonTitle)
					}
				}							
				.frame(height: 30)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
			.disabled(viewModel.isLoading)

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
    }

    @ViewBuilder
    private var downloadItemsSection: some View {
        Section {
			ForEach(viewModel.downloadItems, id: \.id) { download in
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
    }

    @ViewBuilder
    private var errorView: some View {
        ErrorView(errorDetails: $viewModel.errorDetails)
    }
}

#Preview {
    DownloadView()
        .environmentObject(UserPreferences.shared)
}
