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
	let onResumseCanceled: () -> Void

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
		case .inProgress:
			Button {
				onCancel()
			} label: {
				Image(systemName: "xmark.circle")
			}
			.frame(width: 20, height: 20)
		case .canceled:
			Button {
				onResumseCanceled()
			} label: {
				Image(systemName: "arrow.counterclockwise")
			}
			.frame(width: 20, height: 20)
		case .failed, .pending, .completed:
			Button(action: {}, label: {
				Text("")
			})
			.buttonStyle(PlainButtonStyle())
			.frame(width: 20, height: 20)
		}
	}

	@ViewBuilder
	var progressDescription: some View {
		switch state {
		case .pending:
			Text(L10n.waitingDescription)
		case .inProgress(let written, let max):
			let completed: String = String(format: "%.1f", written)
			let outOf: String = max == .infinity || max <= 0 ? "n.a." : String(format: "%.1f", max)
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
			.frame(width: 20, height: 20)
		case .canceled:
			Button {
				onResumseCanceled()
			} label: {
				Image(systemName: "arrow.counterclockwise")
			}
			.frame(width: 20, height: 20)
		case .failed, .pending, .completed:
			Button(action: {}, label: {
				Text("")
			})
			.buttonStyle(PlainButtonStyle())
			.frame(width: 20, height: 20)
		}
	}
}

#Preview(nil, traits: .sizeThatFitsLayout) {
	DownloadTaskView(url: URL(string: "https://loadle.ch")!,
					 state: .pending,
//					 state: .inProgress(written: 0.0, max: -1.0),
//					 state: .inProgress(written: 0.0, max: .infinity),
//					 state: .failed,
//					 state: .completed,
					 onCancel: {},
					 onResumseCanceled: {})
	.environmentObject(Theme.shared)
}
