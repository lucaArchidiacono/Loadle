//
//  SettingsToolbar.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Environments
import Foundation
import SwiftUI

struct SettingsToolbar: ToolbarContent {
//    @EnvironmentObject private var theme: Theme

    let placement: ToolbarItemPlacement
    let onTap: () -> Void

    init(placement: ToolbarItemPlacement = .automatic, onTap: @escaping () -> Void) {
        self.placement = placement
        self.onTap = onTap
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: placement) {
            Button {
                onTap()
            } label: {
                Image(systemName: "gear")
//                    .foregroundStyle(theme.tintColor)
            }
        }
    }
}
