//
//  Duration.swift
//
//
//  Created by Luca Archidiacono on 23.01.2024.
//

import Foundation

extension Duration {
	public var timeInterval: TimeInterval {
		return TimeInterval(components.seconds) + (TimeInterval(components.attoseconds) * 1e-18)
	}
	public var milliseconds: Int {
		return Int(components.seconds.saturatingMultiplication(1000)) + Int(Double(components.attoseconds) * 1e-15)
	}
}
