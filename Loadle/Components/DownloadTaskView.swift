//
//  DownloadTaskView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation
import REST
import SwiftUI

struct DownloadTaskView: View {
	@EnvironmentObject private var theme: Theme

	let url: URL
	let state: REST.DownloadTask.State
	let onCancel: () -> Void
	let onResumeCanceled: () -> Void

	private let frameHeight: CGFloat = 20

    var body: some View {
			VStack(alignment: .leading) {
				Text(url.absoluteString)
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
		case .paused(let written, let max),
			 .inProgress(let written, let max):
			ProgressBar(writtenProgress: written, maxProgress: max)
				.frame(height: 20)
		case .completed:
			ProgressBar(writtenProgress: 0.0, maxProgress: .infinity)
				.frame(height: 20)
		case .failed, .pending, .canceled:
			ProgressBar(writtenProgress: 0.0, maxProgress: -1.0)
				.frame(height: 20)
		}
	}

	@ViewBuilder
	var progressDescription: some View {
		switch state {
		case .pending:
			Text(L10n.waitingDescription)
		case .paused(let written, let max),
			 .inProgress(let written, let max):
			let completed: String = String(format: "%.1f MB", written)
			let outOf: String = max == .infinity || max <= 0 ? "n.a." : String(format: "%.1f MB", max)
			Text(L10n.inProgressDescription(completed, outOf))
		case .completed:
			Text(L10n.completedDescription)
		case .failed:
			Text(L10n.failedDescription)
		case .canceled:
			Text(L10n.canceledDescription)
		}
	}

	@ViewBuilder
	var progressButton: some View {
		switch state {
		case .inProgress:
			Button {
				onCancel()
			} label: {
				Image(systemName: "xmark.circle")
			}
			.frame(width: frameHeight, height: frameHeight)
		case .canceled, .paused:
			Button {
				onResumeCanceled()
			} label: {
				Image(systemName: "arrow.counterclockwise")
			}
			.frame(width: frameHeight, height: frameHeight)
		case .failed, .pending, .completed:
			Button(action: {}, label: {
				Text("")
			})
			.buttonStyle(PlainButtonStyle())
			.frame(width: frameHeight, height: frameHeight)
		}
	}
}

#Preview(nil, traits: .sizeThatFitsLayout) {
	DownloadTaskView(url: URL(string: "https://loadle.ch")!,
//					 state: .pending,
//					 state: .inProgress(written: 0.0, max: -1.0),
//					 state: .inProgress(written: 1.0, max: .infinity),
//					 state: .canceled,
//					 state: .failed,
//					 state: .completed,
					 state: .paused(written: 1.0, max: 5.0),
					 onCancel: {},
					 onResumeCanceled: {})
	.environmentObject(Theme.shared)
}
