//
//  Jittered.swift
//
//
//  Created by Luca Archidiacono on 24.01.2024.
//

import Foundation

public struct Jittered<InnerIterator: IteratorProtocol>: IteratorProtocol where InnerIterator.Element == Duration {
  private var inner: InnerIterator

  public init(_ inner: InnerIterator) {
    self.inner = inner
  }

  public mutating func next() -> Duration? {
    guard let interval = inner.next() else { return nil }

    let jitter = Double.random(in: 0.0 ... 1.0)
    let millis = interval.milliseconds
    let millisWithJitter = millis.saturatingAddition(Int(Double(millis) * jitter))

    return .milliseconds(millisWithJitter)
  }
}
