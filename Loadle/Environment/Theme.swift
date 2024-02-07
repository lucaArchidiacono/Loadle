//
//  Theme.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation
import SwiftUI

fileprivate enum ThemeKey: String {
	case colorScheme, tint, label, primaryBackground, secondaryBackground
	case selectedSet, selectedScheme
	case followSystemColorSchme
}

@MainActor
public final class Theme: ObservableObject {
	@AppStorage("is_previously_set") public var isThemePreviouslySet: Bool = false
	@AppStorage(ThemeKey.selectedScheme.rawValue) public var selectedScheme: ColorScheme = .dark
	@AppStorage(ThemeKey.tint.rawValue) public var tintColor: Color = .black
	@AppStorage(ThemeKey.primaryBackground.rawValue) public var primaryBackgroundColor: Color = .white
	@AppStorage(ThemeKey.secondaryBackground.rawValue) public var secondaryBackgroundColor: Color = .gray
	@AppStorage(ThemeKey.label.rawValue) public var labelColor: Color = .black
	@AppStorage(ThemeKey.selectedSet.rawValue) var storedSet: ColorSetName = .mediumDark
	@AppStorage(ThemeKey.followSystemColorSchme.rawValue) public var followSystemColorScheme: Bool = true

    public static let shared = Theme()

    public var selectedSet: ColorSetName = .mediumDark

    public static var allColorSet: [ColorSet] {
        [
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

    private init() {
		selectedSet = storedSet
    }

    public func applySet(set: ColorSetName) {
        selectedSet = set
        setColor(withName: set)
    }

    public func setColor(withName name: ColorSetName) {
        let colorSet = Theme.allColorSet.filter { $0.name == name }.first ?? MediumDark()
        selectedScheme = colorSet.scheme
        tintColor = colorSet.tintColor
        primaryBackgroundColor = colorSet.primaryBackgroundColor
        secondaryBackgroundColor = colorSet.secondaryBackgroundColor
        labelColor = colorSet.labelColor
        storedSet = name
    }

    public func restoreDefault() {
        applySet(set: selectedScheme == .dark ? .mediumDark : .mediumLight)
        isThemePreviouslySet = true
        storedSet = selectedSet
        followSystemColorScheme = true
    }
}
