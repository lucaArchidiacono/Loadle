//
//  ThemeApplier.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Environments
import Foundation
import Models

import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

public extension View {
    func applyTheme(_ theme: Theme) -> some View {
        modifier(ThemeApplier(theme: theme))
    }
}

@MainActor
struct ThemeApplier: ViewModifier {
    @Environment(\EnvironmentValues.colorScheme) var colorScheme

    var theme: Theme

    func body(content: Content) -> some View {
        content
            .tint(theme.tintColor)
            .preferredColorScheme(colorScheme)
        #if canImport(UIKit)
            .onAppear {
                // If theme is never set before set the default store. This should only execute once after install.
                if !theme.isThemePreviouslySet {
                    theme.applySet(withName: .medium, colorScheme: colorScheme)
                    theme.isThemePreviouslySet = true
                } else if theme.isThemePreviouslySet,
                          let sets = availableColorsSets.first(where: { $0.light.name == theme.selectedSet || $0.dark.name == theme.selectedSet })
                {
                    theme.applySet(withName: colorScheme == .dark ? sets.dark.name : sets.light.name, colorScheme: colorScheme)
                }
                setWindowTint(theme.tintColor)
                setBarsColor(theme.primaryBackgroundColor)
            }
            .onChange(of: theme.tintColor) { _, newValue in
                setWindowTint(newValue)
            }
            .onChange(of: theme.primaryBackgroundColor) { _, newValue in
                setBarsColor(newValue)
            }
            .onChange(of: colorScheme) { _, _ in
                if let sets = availableColorsSets
                    .first(where: { $0.light.name == theme.selectedSet || $0.dark.name == theme.selectedSet })
                {
                    theme.applySet(withName: colorScheme == .dark ? sets.dark.name : sets.light.name, colorScheme: colorScheme)
                }
            }
        #endif
    }

    #if canImport(UIKit)
        private func setWindowUserInterfaceStyle(from colorScheme: ColorScheme) {
            switch colorScheme {
            case .dark:
                setWindowUserInterfaceStyle(.dark)
            case .light:
                setWindowUserInterfaceStyle(.light)
            @unknown default:
                fatalError()
            }
        }

        private func setWindowUserInterfaceStyle(_ userInterfaceStyle: UIUserInterfaceStyle) {
            for window in allWindows() {
                window.overrideUserInterfaceStyle = userInterfaceStyle
            }
        }

        private func setWindowTint(_ color: Color) {
            for window in allWindows() {
                window.tintColor = UIColor(color)
            }
        }

        private func setBarsColor(_ color: Color) {
            UINavigationBar.appearance().isTranslucent = true
            UINavigationBar.appearance().barTintColor = UIColor(color)
        }

        private func allWindows() -> [UIWindow] {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
        }
    #endif
}
