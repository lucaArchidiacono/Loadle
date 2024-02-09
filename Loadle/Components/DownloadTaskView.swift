//
//  DownloadTaskView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation
import SwiftUI

struct DownloadTaskView: View {
	@EnvironmentObject private var theme: Theme

	let title: String
	let state: Download.State

	let onPause: () -> Void
	let onResume: () -> Void

	private let frameHeight: CGFloat = 20

    var body: some View {
		VStack(alignment: .leading) {
			Text(title)
				.font(.headline)

			HStack {
				progressBar
				progressButton
			}
			progressDescription
		}
		.applyTheme(theme)
    }

	@ViewBuilder
	var progressBar: some View {
		switch state {
		case .progress(let currentBytes, let totalBytes):
			ProgressBar(currentBytes: currentBytes, totalBytes: totalBytes)
				.frame(height: 20)
		case .success:
			ProgressBar(currentBytes: 0.0, totalBytes: .infinity)
				.frame(height: 20)
		case .pending:
			ProgressBar(currentBytes: 0.0, totalBytes: 1.0)
				.frame(height: 20)
		case .paused, .failed:
			ProgressBar(currentBytes: 0.0, totalBytes: -1.0)
				.frame(height: 20)
		}
	}

	@ViewBuilder
	var progressDescription: some View {
		switch state {
		case .progress(let currentBytes, let totalBytes):
			let completed: String = String(format: "%.1f MB", currentBytes / 1_000_000)
			let outOf: String = totalBytes == .infinity || totalBytes <= 0 ? "n.a." : String(format: "%.1f MB", totalBytes / 1_000_000)
			Text(L10n.inProgressDescription(completed, outOf))
		case .success:
			Text(L10n.completedDescription)
		case .paused:
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
				onPause()
			} label: {
				Image(systemName: "xmark.circle")
			}
			.frame(width: frameHeight, height: frameHeight)
		case .paused:
			Button {
				onResume()
			} label: {
				Image(systemName: "arrow.counterclockwise")
			}
			.frame(width: frameHeight, height: frameHeight)
		case .failed, .pending, .success:
			Button(action: {}, label: {
				Text("")
			})
			.buttonStyle(PlainButtonStyle())
			.frame(width: frameHeight, height: frameHeight)
		}
	}
}

#Preview(nil, traits: .sizeThatFitsLayout) {
	DownloadTaskView(title: "HelloWorld.mp3",
					 state: .pending,
					 //					 state: .inProgress(written: 0.0, max: -1.0),
					 //					 state: .inProgress(written: 1.0, max: .infinity),
					 //					 state: .canceled,
					 //					 state: .failed,
					 //					 state: .completed,
					 //					 state: .paused(written: 1.0, max: 5.0),
					 onPause: {},
					 onResume: {})
	.environmentObject(Theme.shared)
}
