//
//  iOSCheckBoxToggleStyle.swift
//  Loadle
//
//  Created by Luca Archidiacono on 09.02.2024.
//

import Foundation
import SwiftUI

struct iOSCheckboxToggleStyle: ToggleStyle {
	func makeBody(configuration: Configuration) -> some View {
		Button(action: {
			configuration.isOn.toggle()
		}, label: {
			HStack {
				configuration.label
				Image(systemName: configuration.isOn ? "checkmark.square" : "square")
			}
		})
	}
}
