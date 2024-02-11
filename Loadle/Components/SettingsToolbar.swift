//
//  SettingsButton.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import SwiftUI

struct SettingsToolbar: ToolbarContent {
	let onTap: () -> Void

	var body: some ToolbarContent {
		ToolbarItem(placement: .topBarTrailing) {
			Button {
				onTap()
			} label: {
				Image(systemName: "gear")
			}
		}
	}
}
