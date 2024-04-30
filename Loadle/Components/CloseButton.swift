//
//  CloseButton.swift
//  Loadle
//
//  Created by Luca Archidiacono on 28.04.2024.
//

import Foundation
import SwiftUI
import UIKit

struct CloseButton: UIViewRepresentable {
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .close)
        button.addTarget(context.coordinator, action: #selector(Coordinator.perform), for: .primaryActionTriggered)
        return button
    }

    func updateUIView(_: UIButton, context: Context) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func perform() {
            action()
        }
    }
}
