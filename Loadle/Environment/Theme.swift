//
//  Theme.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation
import SwiftUI

@MainActor
public final class Theme: ObservableObject {
    class ThemeStorage {
        enum ThemeKey: String {
            case colorScheme, tint, label, primaryBackground, secondaryBackground
            case selectedSet, selectedScheme
            case followSystemColorSchme
        }

        @AppStorage("is_previously_set") public var isThemePreviouslySet: Bool = false
        @AppStorage(ThemeKey.selectedScheme.rawValue) public var selectedScheme: ColorScheme = .dark
        @AppStorage(ThemeKey.tint.rawValue) public var tintColor: Color = .black
        @AppStorage(ThemeKey.primaryBackground.rawValue) public var primaryBackgroundColor: Color = .white
        @AppStorage(ThemeKey.secondaryBackground.rawValue) public var secondaryBackgroundColor: Color = .gray
        @AppStorage(ThemeKey.label.rawValue) public var labelColor: Color = .black
        @AppStorage(ThemeKey.selectedSet.rawValue) var storedSet: ColorSetName = .iceCubeDark
        @AppStorage(ThemeKey.followSystemColorSchme.rawValue) public var followSystemColorScheme: Bool = true

        init() {}
    }

    private let themeStorage = ThemeStorage()

    public var isThemePreviouslySet: Bool {
        didSet {
            themeStorage.isThemePreviouslySet = isThemePreviouslySet
        }
    }

    public var selectedScheme: ColorScheme {
        didSet {
            themeStorage.selectedScheme = selectedScheme
        }
    }

    public var tintColor: Color {
        didSet {
            themeStorage.tintColor = tintColor
        }
    }

    public var primaryBackgroundColor: Color {
        didSet {
            themeStorage.primaryBackgroundColor = primaryBackgroundColor
        }
    }

    public var secondaryBackgroundColor: Color {
        didSet {
            themeStorage.secondaryBackgroundColor = secondaryBackgroundColor
        }
    }

    public var labelColor: Color {
        didSet {
            themeStorage.labelColor = labelColor
        }
    }

    private var storedSet: ColorSetName {
        didSet {
            themeStorage.storedSet = storedSet
        }
    }

    public var followSystemColorScheme: Bool {
        didSet {
            themeStorage.followSystemColorScheme = followSystemColorScheme
        }
    }

    public static let shared = Theme()

    public var selectedSet: ColorSetName = .iceCubeDark

    public static var allColorSet: [ColorSet] {
        [
            IceCubeDark(),
            IceCubeLight(),
            IceCubeNeonDark(),
            IceCubeNeonLight(),
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
        isThemePreviouslySet = themeStorage.isThemePreviouslySet
        selectedScheme = themeStorage.selectedScheme
        tintColor = themeStorage.tintColor
        primaryBackgroundColor = themeStorage.primaryBackgroundColor
        secondaryBackgroundColor = themeStorage.secondaryBackgroundColor
        labelColor = themeStorage.labelColor
        storedSet = themeStorage.storedSet
        followSystemColorScheme = themeStorage.followSystemColorScheme
        selectedSet = storedSet
    }

    public func applySet(set: ColorSetName) {
        selectedSet = set
        setColor(withName: set)
    }

    public func setColor(withName name: ColorSetName) {
        let colorSet = Theme.allColorSet.filter { $0.name == name }.first ?? IceCubeDark()
        selectedScheme = colorSet.scheme
        tintColor = colorSet.tintColor
        primaryBackgroundColor = colorSet.primaryBackgroundColor
        secondaryBackgroundColor = colorSet.secondaryBackgroundColor
        labelColor = colorSet.labelColor
        storedSet = name
    }

    public func restoreDefault() {
        applySet(set: themeStorage.selectedScheme == .dark ? .iceCubeDark : .iceCubeLight)
        isThemePreviouslySet = true
        storedSet = selectedSet
        followSystemColorScheme = true
    }
}
