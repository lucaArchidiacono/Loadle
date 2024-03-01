//
//  ProgressBar.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Environments
import Foundation
import Shimmer
import SwiftUI

struct ProgressBar: View {
//    @EnvironmentObject private var theme: Theme

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
//                    .foregroundColor(theme.tintColor)

                var width: CGFloat {
                    var value: CGFloat
                    if currentProgress < 0 {
                        // When totalBytes is unkown we get a negative number. Which means currenProgress is then negative. Which results into an unkown currentProgress size. Hence we indicate the full bar.
                        value = geometry.size.width
                    } else {
                        value = min(CGFloat(currentProgress) * geometry.size.width, geometry.size.width)
                    }
                    return value
                }
                Rectangle()
                    .frame(width: width, height: geometry.size.height)
//                    .foregroundStyle(theme.tintColor)
                    .shimmering(gradient: Gradient(colors: [.black, .black.opacity(0.5), .black]), bandSize: 10)
            }
            .cornerRadius(5.0)
        }
    }
}

#Preview(nil, traits: .sizeThatFitsLayout) {
    ProgressBar(currentBytes: 1.0, totalBytes: 2.0)
        .frame(width: 200, height: 20)
        .environmentObject(Theme.shared)
}
