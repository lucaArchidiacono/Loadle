//
//  ProgressBar.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation
import SwiftUI
import Shimmer

struct ProgressBar: View {
	@EnvironmentObject private var theme: Theme
	
	let currentBytes: Double
	let totalBytes: Double

	private var currentProgress: Double {
		return currentBytes / totalBytes
	}

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
					.foregroundColor(theme.tintColor)

				var width: CGFloat {
					return max(min(CGFloat(currentProgress) * geometry.size.width, geometry.size.width), 0)
				}
                Rectangle()
					.frame(width: width, height: geometry.size.height)
					.foregroundStyle(theme.tintColor)
					.shimmering(gradient: Gradient(colors: [.black, .black.opacity(0.5), .black]), bandSize: 10)

            }
            .cornerRadius(5.0)
        }
    }
}

#Preview(nil, traits: .sizeThatFitsLayout) {
	ProgressBar(currentBytes: 1.0, totalBytes: -1.0)
		.frame(width: 200, height: 20)
		.environmentObject(Theme.shared)
}
