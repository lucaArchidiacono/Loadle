//
//  SubscriptionSectionView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 29.04.2024.
//

import Foundation
import SwiftUI
import Generator
import Constants

struct SubscriptionSectionView: View {
	let onTap: () -> Void

	var body: some View {
		VStack(spacing: 16) {
			Text(L10n.appTitle)
				.font(.headline)
			Text(L10n.appSubscriptionBannerDescription)
				.multilineTextAlignment(.center)
			Button(action: {
				onTap()
			}) {
				Text(L10n.appSubscriptionBannerButtonTitle)
					.frame(maxWidth: .infinity)
			}
			.buttonStyle(.borderedProminent)
		}
		.padding()
	}
}

#Preview {
	SubscriptionSectionView(onTap: {})
}
