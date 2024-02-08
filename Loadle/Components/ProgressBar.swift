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
	
	let writtenProgress: Double
	let maxProgress: Double

	private var currentProgress: Double {
		if maxProgress == .infinity { return maxProgress }
		else { return writtenProgress / maxProgress }
	}

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.systemTeal))

                Rectangle()
                    .frame(width: min(CGFloat(currentProgress) * geometry.size.width, geometry.size.width), height: geometry.size.height)
					.foregroundStyle(theme.tintColor)
					.shimmering(gradient: Gradient(colors: [.black, .black.opacity(0.5), .black]), bandSize: 10)

            }
            .cornerRadius(5.0)
        }
    }
}

#Preview(nil, traits: .sizeThatFitsLayout) {
	ProgressBar(writtenProgress: 1.0, maxProgress: 4.0)
		.environmentObject(Theme.shared)
}
