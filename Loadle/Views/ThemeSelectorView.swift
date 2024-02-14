//
//  ThemeSelectorView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 07.02.2024.
//

import Foundation
import Environments
import Models
import Generator
import SwiftUI

struct ThemeSelectorView: View {
	@EnvironmentObject private var theme: Theme

	var body: some View {
		List {
			ForEach(availableColorsSets, id: \.id) { colorSet in
				HStack {
					ThemeBoxView(color: colorSet.light)
					ThemeBoxView(color: colorSet.dark)
				}
				.listRowSeparator(.hidden)
				.listRowBackground(Color.clear)
			}
		}
		.listStyle(.plain)
		.scrollContentBackground(.hidden)
		.background(theme.secondaryBackgroundColor)
		.navigationTitle(L10n.settingsThemeTitle)
		.applyTheme(theme)
	}
}

struct ThemeBoxView: View {
	@EnvironmentObject private var theme: Theme
	private let gutterSpace = 8.0
	@State private var isSelected = false

	var color: ColorSet

	var body: some View {
		ZStack(alignment: .topTrailing) {
			Rectangle()
				.foregroundColor(.white)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.cornerRadius(4)
				.shadow(radius: 2, x: 2, y: 4)
				.accessibilityHidden(true)

			VStack(spacing: gutterSpace) {
				Text(color.name.rawValue)
					.foregroundColor(color.tintColor)
					.font(.system(size: 20))
					.fontWeight(.bold)

				Text("design.theme.toots-preview")
					.foregroundColor(color.labelColor)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.padding()
					.background(color.primaryBackgroundColor)

				Text("#icecube, #techhub")
					.foregroundColor(color.tintColor)
				if isSelected {
					HStack {
						Spacer()
						Image(systemName: "checkmark.seal.fill")
							.resizable()
							.frame(width: 20, height: 20)
							.foregroundColor(.green)
					}
				} else {
					HStack {
						Spacer()
						Circle()
							.strokeBorder(color.tintColor, lineWidth: 1)
							.background(Circle().fill(color.primaryBackgroundColor))
							.frame(width: 20, height: 20)
					}
				}
			}
			.frame(maxWidth: .infinity)
			.padding()
			.background(color.secondaryBackgroundColor)
			.font(.system(size: 15))
			.cornerRadius(4)
		}
		.onAppear {
			isSelected = theme.selectedSet.rawValue == color.name.rawValue
		}
		.onChange(of: theme.selectedSet) { _, newValue in
			isSelected = newValue.rawValue == color.name.rawValue
		}
		.onTapGesture {
			let currentScheme = theme.selectedScheme
			if color.scheme != currentScheme {
				theme.followSystemColorScheme = false
			}
			theme.applySet(set: color.name)
		}
	}
}

#Preview {
	ThemeSelectorView()
		.environmentObject(Theme.shared)
}
