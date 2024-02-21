//
//  ErrorView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 09.02.2024.
//

import Foundation
import Models
import SwiftUI

struct ErrorView: View {
    @State private var showAlert = false

    @Binding var errorDetails: ErrorDetails?

    var body: some View {
        ZStack {
            if let errorDetails {
                ZStack {}
                    .alert(errorDetails.title, isPresented: $showAlert) {
                        ForEach(errorDetails.actions, id: \.self) { action in
                            switch action {
                            case let .primary(title, action):
                                Button(
                                    role: .cancel,
                                    action: {
                                        action?()
                                        showAlert = false
                                        self.errorDetails = nil
                                    },
                                    label: { Text(title) }
                                )
                            case let .secondary(title, action):
                                Button(
                                    action: {
                                        action?()
                                        showAlert = false
                                        self.errorDetails = nil
                                    },
                                    label: { Text(title) }
                                )
                            case let .destructive(title, action):
                                Button(
                                    role: .destructive,
                                    action: {
                                        action?()
                                        showAlert = false
                                        self.errorDetails = nil
                                    },
                                    label: { Text(title) }
                                )
                            }
                        }
                    } message: {
                        Text(errorDetails.description)
                    }
            }
        }
        .onChange(of: errorDetails) { _, newErrorDetails in
            showAlert = newErrorDetails != nil
        }
    }
}

#Preview {
    ErrorView(errorDetails: .constant(.init(
        title: "Something went wrong",
        description: "Hey there, something went wrong! Please press the button to dismiss.",
        actions: [.primary(title: "Ok") {}]
    )))
}
