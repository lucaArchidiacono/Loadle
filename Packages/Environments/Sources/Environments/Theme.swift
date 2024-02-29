//
//  Theme.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation
import Fundamentals
import Models
import SwiftUI

private enum ThemeKey: String {
    case tint, label, primaryBackground, secondaryBackground
    case selectedSet, selectedScheme
}

@MainActor
public final class Theme: ObservableObject {
    @AppStorage("is_previously_set") public var isThemePreviouslySet: Bool = false
    @AppStorage(ThemeKey.tint.rawValue) public var tintColor: Color = .init(hex: 0x1A8917)
    @AppStorage(ThemeKey.primaryBackground.rawValue) public var primaryBackgroundColor: Color = .init(hex: 0x121212)
    @AppStorage(ThemeKey.secondaryBackground.rawValue) public var secondaryBackgroundColor: Color = .init(hex: 0x191919)
    @AppStorage(ThemeKey.label.rawValue) public var labelColor: Color = .white
    @AppStorage(ThemeKey.selectedSet.rawValue) public var selectedSet: ColorSetName = .medium

    public static let shared = Theme()

    public static var allColorSet: [ColorSet] {
        [
            SystemDark(),
            SystemLight(),
            DesertDark(),
            DesertLight(),
            NemesisDark(),
            NemesisLight(),
            MediumLight(),
            MediumDark(),
            ConstellationLight(),
            ConstellationDark(),
            ThreadsLight(),
            ThreadsDark(),
        ]
    }

    private init() {}

    public func applySet(withName name: ColorSetName, colorScheme: SwiftUI.ColorScheme) {
        selectedSet = name
        setColor(withName: name, colorScheme: colorScheme)
    }

    public func setColor(withName name: ColorSetName, colorScheme: SwiftUI.ColorScheme) {
        let colorSet = Theme.allColorSet.filter { $0.name == name && $0.scheme == colorScheme }.first ?? MediumDark()
        tintColor = colorSet.tintColor
        primaryBackgroundColor = colorSet.primaryBackgroundColor
        secondaryBackgroundColor = colorSet.secondaryBackgroundColor
        labelColor = colorSet.labelColor
        selectedSet = colorSet.name
    }
}
