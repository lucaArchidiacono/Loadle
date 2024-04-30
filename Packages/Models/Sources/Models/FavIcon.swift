//
//  FavIcon.swift
//
//
//  Created by Luca Archidiacono on 27.03.2024.
//

import Foundation

public struct FavIcon {
    public enum Size: Int, CaseIterable {
        case s = 16, m = 32, l = 64, xl = 128, xxl = 256, xxxl = 512
    }

    private let domain: String

    public init(_ domain: String) {
        self.domain = domain
    }

    public subscript(_ size: Size) -> String {
        "https://www.google.com/s2/favicons?sz=\(size.rawValue)&domain=\(domain)"
    }
}
