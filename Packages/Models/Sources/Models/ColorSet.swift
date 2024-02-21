//
//  ColorSet.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation
import Generator
import SwiftUI

public let availableColorsSets: [ColorSetCouple] =
    [.init(light: DesertLight(), dark: DesertDark()),
     .init(light: NemesisLight(), dark: NemesisDark()),
     .init(light: MediumLight(), dark: MediumDark()),
     .init(light: ConstellationLight(), dark: ConstellationDark()),
     .init(light: ThreadsLight(), dark: ThreadsDark())]

public protocol ColorSet {
    var name: ColorSetName { get }
    var nameWithScheme: String { get }
    var scheme: SwiftUI.ColorScheme { get }
    var tintColor: Color { get set }
    var primaryBackgroundColor: Color { get set }
    var secondaryBackgroundColor: Color { get set }
    var labelColor: Color { get set }
}

public extension ColorScheme {
    var name: String {
        switch self {
        case .dark:
            L10n.darkTheme
        case .light:
            L10n.lightTheme
        @unknown default:
            fatalError()
        }
    }
}

public enum ColorSetName: String {
    case desert = "Desert"
    case nemesis = "Nemesis"
    case medium = "Medium"
    case constellation = "Constellation"
    case threads = "Threads"
}

public struct ColorSetCouple: Identifiable {
    public var id: String { dark.nameWithScheme + light.nameWithScheme }
    public var setName: ColorSetName { dark.name }

    public let light: ColorSet
    public let dark: ColorSet
}

public struct DesertDark: ColorSet {
    public var name: ColorSetName = .desert
    public var scheme: SwiftUI.ColorScheme = .dark
    public var tintColor: Color = .init(hex: 0xDF915E)
    public var primaryBackgroundColor: Color = .init(hex: 0x433744)
    public var secondaryBackgroundColor: Color = .init(hex: 0x654868)
    public var labelColor: Color = .white

    public var nameWithScheme: String { "\(name) - \(scheme.name)" }

    public init() {}
}

public struct DesertLight: ColorSet {
    public var name: ColorSetName = .desert
    public var scheme: SwiftUI.ColorScheme = .light
    public var tintColor: Color = .init(hex: 0xDF915E)
    public var primaryBackgroundColor: Color = .init(hex: 0xFCF2EB)
    public var secondaryBackgroundColor: Color = .init(hex: 0xEEEDE7)
    public var labelColor: Color = .black

    public var nameWithScheme: String { "\(name) - \(scheme.name)" }

    public init() {}
}

public struct NemesisDark: ColorSet {
    public var name: ColorSetName = .nemesis
    public var scheme: ColorScheme = .dark
    public var tintColor: Color = .init(hex: 0x17A2F2)
    public var primaryBackgroundColor: Color = .init(hex: 0x000000)
    public var secondaryBackgroundColor: Color = .init(hex: 0x151E2B)
    public var labelColor: Color = .white

    public var nameWithScheme: String { "\(name) - \(scheme.name)" }

    public init() {}
}

public struct NemesisLight: ColorSet {
    public var name: ColorSetName = .nemesis
    public var scheme: ColorScheme = .light
    public var tintColor: Color = .init(hex: 0x17A2F2)
    public var primaryBackgroundColor: Color = .init(hex: 0xFFFFFF)
    public var secondaryBackgroundColor: Color = .init(hex: 0xE8ECEF)
    public var labelColor: Color = .black

    public var nameWithScheme: String { "\(name) - \(scheme.name)" }

    public init() {}
}

public struct MediumDark: ColorSet {
    public var name: ColorSetName = .medium
    public var scheme: ColorScheme = .dark
    public var tintColor: Color = .init(hex: 0x1A8917)
    public var primaryBackgroundColor: Color = .init(hex: 0x121212)
    public var secondaryBackgroundColor: Color = .init(hex: 0x191919)
    public var labelColor: Color = .white

    public var nameWithScheme: String { "\(name) - \(scheme.name)" }

    public init() {}
}

public struct MediumLight: ColorSet {
    public var name: ColorSetName = .medium
    public var scheme: ColorScheme = .light
    public var tintColor: Color = .init(hex: 0x1A8917)
    public var primaryBackgroundColor: Color = .init(hex: 0xFFFAFA)
    public var secondaryBackgroundColor: Color = .init(hex: 0xF4F0EC)
    public var labelColor: Color = .black

    public var nameWithScheme: String { "\(name) - \(scheme.name)" }

    public init() {}
}

public struct ConstellationDark: ColorSet {
    public var name: ColorSetName = .constellation
    public var scheme: ColorScheme = .dark
    public var tintColor: Color = .init(hex: 0xFFD966)
    public var primaryBackgroundColor: Color = .init(hex: 0x09192C)
    public var secondaryBackgroundColor: Color = .init(hex: 0x304C7A)
    public var labelColor: Color = .init(hex: 0xE2E4E2)

    public var nameWithScheme: String { "\(name) - \(scheme.name)" }

    public init() {}
}

public struct ConstellationLight: ColorSet {
    public var name: ColorSetName = .constellation
    public var scheme: ColorScheme = .light
    public var tintColor: Color = .init(hex: 0xC82238)
    public var primaryBackgroundColor: Color = .init(hex: 0xF4F5F7)
    public var secondaryBackgroundColor: Color = .init(hex: 0xACC7E5)
    public var labelColor: Color = .black

    public var nameWithScheme: String { "\(name) - \(scheme.name)" }

    public init() {}
}

public struct ThreadsDark: ColorSet {
    public var name: ColorSetName = .threads
    public var scheme: ColorScheme = .dark
    public var tintColor: Color = .init(hex: 0x0095F6)
    public var primaryBackgroundColor: Color = .init(hex: 0x101010)
    public var secondaryBackgroundColor: Color = .init(hex: 0x181818)
    public var labelColor: Color = .init(hex: 0xE2E4E2)

    public var nameWithScheme: String { "\(name) - \(scheme.name)" }

    public init() {}
}

public struct ThreadsLight: ColorSet {
    public var name: ColorSetName = .threads
    public var scheme: ColorScheme = .light
    public var tintColor: Color = .init(hex: 0x0095F6)
    public var primaryBackgroundColor: Color = .init(hex: 0xFFFFFF)
    public var secondaryBackgroundColor: Color = .init(hex: 0xFFFFFF)
    public var labelColor: Color = .black

    public var nameWithScheme: String { "\(name) - \(scheme.name)" }

    public init() {}
}
