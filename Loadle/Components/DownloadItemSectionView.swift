//
//  DownloadItemSectionView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Environments
import Foundation
import Fundamentals
import Generator
import Models
import SwiftUI

struct DownloadItemSectionView: View {
    let title: String
    let state: DownloadItem.State
	let iconProvider: NSItemProvider?

    let onCancel: () -> Void
    let onResume: () -> Void

    private let height: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
				AsyncImageProvider(itemProvider: iconProvider, placeholder: Image(systemName: "bookmark.fill"), content: { image in
					image
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 20, height: 20)
				})

				Text(title)
                    .font(.headline)
					.frame(height: 20)
            }
            HStack {
                progressBar
                progressButton
            }
            progressDescription
        }
    }

    @ViewBuilder
    var progressBar: some View {
        switch state {
        case .pending:
            ProgressBar(currentBytes: 0.0, totalBytes: 1.0)
                .frame(height: height)
        case let .progress(currentBytes, totalBytes):
            ProgressBar(currentBytes: currentBytes, totalBytes: totalBytes)
                .frame(height: height)
        case .completed:
            ProgressBar(currentBytes: 1.0, totalBytes: 1.0)
                .frame(height: height)
        case .cancelled, .failed:
            ProgressBar(currentBytes: 0.0, totalBytes: -1.0)
                .frame(height: height)
        }
    }

    @ViewBuilder
    var progressDescription: some View {
        switch state {
        case let .progress(currentBytes, totalBytes):
            let completed: String = .init(format: "%.1f MB", currentBytes / 1_000_000)
            let outOf: String = totalBytes == .infinity || totalBytes <= 0 ? "n.a." : String(format: "%.1f MB", totalBytes / 1_000_000)
            Text(L10n.inProgressDescription(completed, outOf))
        case .completed:
            Text(L10n.completedDescription)
        case .cancelled:
            Text(L10n.canceledDescription)
        case .failed:
            Text(L10n.failedDescription)
        case .pending:
            Text(L10n.waitingDescription)
        }
    }

    @ViewBuilder
    var progressButton: some View {
        switch state {
        case .progress:
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark.circle")
            }
            .frame(width: height, height: height)
        case .cancelled, .failed:
            Button {
                onResume()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .frame(width: height, height: height)
        case .pending, .completed:
            Button(action: {}, label: {
                Text("")
            })
            .buttonStyle(PlainButtonStyle())
            .frame(width: height, height: height)
        }
    }
}

#Preview {
    List {
        Section {
            DownloadItemSectionView(title: "HelloWorld.mp3",
                                    state: .progress(currentBytes: 1.0, totalBytes: -1.0),
                                    //					 state: .paused,
                                    //					 state: .failed(error: NSError()),
                                    //					 state: .success(url: URL(string: "https://youtube.com")!),
									iconProvider: nil,
                                    onCancel: {},
                                    onResume: {})
        }
        .listRowBackground(Theme.shared.secondaryBackgroundColor)
    }
    .environmentObject(Theme.shared)
}
