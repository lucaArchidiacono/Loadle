//
//  CloseToolbar.swift
//  Loadle
//
//  Created by Luca Archidiacono on 28.04.2024.
//

import Foundation
import SwiftUI
import UIKit

struct CloseToolbar: ToolbarContent {
    let placement: ToolbarItemPlacement
    let onTap: () -> Void

    init(placement: ToolbarItemPlacement = .automatic, onTap: @escaping () -> Void) {
        self.placement = placement
        self.onTap = onTap
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: placement) {
            CloseButton {
                onTap()
            }
        }
    }
}
