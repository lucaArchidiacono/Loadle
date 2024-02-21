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
    @Environment(DownloadService.self) private var downloadService: DownloadService

    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var theme: Theme

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
            CancelToolbar(placement: .topBarLeading) {
                dismiss()
            }
        }
        .applyTheme(theme)
        .navigationBarTitle(L10n.download)
        .background(theme.primaryBackgroundColor)
    }

    @ViewBuilder
    var downloadView: some View {
        List {
            downloadSection
            downloadItemsSection
            //			assetItemsSection
        }
        .background(theme.secondaryBackgroundColor)
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
            .background(theme.secondaryBackgroundColor)
            .cornerRadius(8)
            .foregroundColor(theme.tintColor)

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
        .listRowBackground(theme.primaryBackgroundColor)
    }

    @ViewBuilder
    private var downloadItemsSection: some View {
        Section {
            ForEach(downloadService.store.downloads, id: \.id) { download in
                DownloadItemSectionView(
                    title: download.title,
                    state: download.state,
                    iconProvider: download.metaData.iconProvider,
                    onCancel: {
                        downloadService.cancel(id: download.id)
                    },
                    onResume: {
                        downloadService.resume(id: download.id)
                    }
                )
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive,
                           action: { downloadService.delete(id: download.id) },
                           label: { Image(systemName: "trash") })
                }
            }
        }
        .listRowBackground(theme.secondaryBackgroundColor)
    }

    //	@ViewBuilder
    //	private var assetItemsSection: some View {
    //		Section {
    //			ForEach(viewModel.loadedAssets, id: \.id) { asset in
    //				AssetItemSectionView(
    //					title: asset.title,
    //					image: asset.image,
    //					fileURL: asset.fileURL)
    //				.swipeActions(edge: .trailing) {
    //					Button(role: .destructive,
    //						   action: { /*viewModel.delete(asset: asset)*/ } ,
    //						   label: { Image(systemName: "trash") } )
    //				}
    //			}
    //		}
    //		.listRowBackground(theme.secondaryBackgroundColor)
    //	}

    @ViewBuilder
    private var errorView: some View {
        ErrorView(errorDetails: $viewModel.errorDetails)
    }
}

#Preview {
    DownloadView()
        .environmentObject(Theme.shared)
        .environmentObject(UserPreferences.shared)
        .environment(DownloadService.shared)
        .environment(Router())
}
