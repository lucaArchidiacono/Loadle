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
import UIKit
import SwiftUI

struct DownloadView: View {
	enum FocusedField {
		case url
	}

    @Environment(\.dismiss) private var dismiss: DismissAction

	@EnvironmentObject private var preferences: UserPreferences

	@FocusState private var focusedField: FocusedField?

    @State private var viewModel = DownloadViewModel()

	private var cornerRadius: CGFloat = 8.0

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
		.onAppear {
			focusedField = .url
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
				Group {
					Image(systemName: "link")
						.aspectRatio(contentMode: .fit)
						.frame(width: 30)
					TextField(L10n.pasteLink, text: $viewModel.url)
						.focused($focusedField, equals: .url)
				}
				.frame(height: 60)
			}
			.padding(.horizontal, 8)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(cornerRadius)
			.shadow(radius: 4, x: 4, y: 4)

            Button {
				viewModel.startDownload(using: viewModel.url)
                focusedField = nil
            } label: {
				Group {
					if viewModel.isLoading {
						ProgressView()
					} else {
						Text(L10n.downloadButtonTitle)
							.foregroundStyle(.white)
					}
				}
				.frame(height: 30)
				.frame(maxWidth: .infinity)
            }
			.buttonStyle(
				.roundedAndShadow(
					cornerRadius: cornerRadius,
					labelPadding: EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
				)
			)
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
