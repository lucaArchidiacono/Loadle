//
//  InfoToolbar.swift
//  Loadle
//
//  Created by Luca Archidiacono on 29.04.2024.
//

import Foundation
import SwiftUI

struct InfoToolbar: ToolbarContent {
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
                Image(systemName: "info.circle")
            }
        }
    }
}
