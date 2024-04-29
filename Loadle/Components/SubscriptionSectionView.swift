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
		VStack {
			Text(L10n.appTitle)
				.font(.title2)
				.bold()
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
	}
}

#Preview {
	SubscriptionSectionView(onTap: {})
}
