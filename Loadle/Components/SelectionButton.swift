//
//  SelectionButton.swift
//  Loadle
//
//  Created by Luca Archidiacono on 21.02.2024.
//

import Foundation
import Environments
import SwiftUI

struct SelectionButton: View {
	@Environment(\.colorScheme) private var colorScheme: ColorScheme

//	@EnvironmentObject private var theme: Theme

	let title: String
	let isSelected: Bool
	let onTap: () -> Void

	init(title: String, isSelected: Bool, onTap: @escaping () -> Void) {
		self.title = title
		self.isSelected = isSelected
		self.onTap = onTap
	}

	var body: some View {
		Button {
			onTap()
		} label: {
			HStack {
				Text(title)
				Spacer()
				if isSelected {
					Image(systemName: "checkmark")
//						.foregroundStyle(theme.tintColor)
				}
			}
		}
		.tint(colorScheme == .dark ? .white : .black)
	}
}
