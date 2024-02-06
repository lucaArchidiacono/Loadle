//
//  ExponentialBackoff.swift
//
//
//  Created by Luca Archidiacono on 24.01.2024.
//

import Foundation

public struct ExponentialBackoff: IteratorProtocol {
    private var _next: Duration
    private let multiplier: UInt64
    private let maxDelay: Duration?

    public init(initial: Duration, multiplier: UInt64, maxDelay: Duration? = nil) {
        _next = initial
        self.multiplier = multiplier
        self.maxDelay = maxDelay
    }

    public mutating func next() -> Duration? {
        let next = _next

        if let maxDelay, next > maxDelay {
            return maxDelay
        }

        _next = next * Int(multiplier)

        return next
    }
}
