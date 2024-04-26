//
//  ButtonStyles.swift
//  Loadle
//
//  Created by Luca Archidiacono on 26.04.2024.
//

import Foundation
import SwiftUI

struct RoundedAndShadowButtonStyle: ButtonStyle {
	private let cornerRadius: CGFloat
	private let labelPadding: EdgeInsets
	private let shadowRadius: CGFloat

	init(cornerRadius: CGFloat, labelPadding: EdgeInsets, shadowRadius: CGFloat) {
		self.cornerRadius = cornerRadius
		self.labelPadding = labelPadding
		self.shadowRadius = shadowRadius
	}

	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.foregroundColor(.white)
			.padding(labelPadding)
			.background(
				RoundedRectangle(cornerRadius: cornerRadius)
					.foregroundColor(.blue)
			)
			.compositingGroup()
			// Adjust interactive animations based on isPressing
			.shadow(radius: configuration.isPressed ? 0 : shadowRadius, x: 0, y: configuration.isPressed ? 0 : shadowRadius)
			.scaleEffect(configuration.isPressed ? 0.95 : 1)
			.animation(.spring(), value: configuration.isPressed)
	}
}

extension ButtonStyle where Self == RoundedAndShadowButtonStyle {
	static func roundedAndShadow(cornerRadius: CGFloat, labelPadding: EdgeInsets, shadowRadius: CGFloat = 4) -> RoundedAndShadowButtonStyle {
		RoundedAndShadowButtonStyle(cornerRadius: cornerRadius, labelPadding: labelPadding, shadowRadius: shadowRadius)
	}
}
