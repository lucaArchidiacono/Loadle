//
//  DoneToolbar.swift
//  Loadle
//
//  Created by Luca Archidiacono on 21.02.2024.
//

import Environments
import Foundation
import Generator
import SwiftUI

struct DoneToolbar: ToolbarContent {
    let placement: ToolbarItemPlacement
    let onTap: () -> Void

    init(placement: ToolbarItemPlacement = .automatic, onTap: @escaping () -> Void) {
        self.placement = placement
        self.onTap = onTap
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: placement) {
            Button(L10n.done) {
                onTap()
            }
        }
    }
}
