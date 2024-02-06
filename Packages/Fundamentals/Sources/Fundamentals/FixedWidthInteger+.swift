//
//  FixedWidthInteger+.swift
//
//
//  Created by Luca Archidiacono on 24.01.2024.
//

import Foundation

extension FixedWidthInteger {
	/// Saturating integer multiplication. Computes `self * rhs`, saturating at the numeric bounds
	/// instead of overflowing.
	public func saturatingMultiplication(_ rhs: Self) -> Self {
		let (partialValue, isOverflow) = multipliedReportingOverflow(by: rhs)

		if isOverflow {
			return signum() == rhs.signum() ? .max : .min
		} else {
			return partialValue
		}
	}

	/// Saturating integer addition. Computes `self + rhs`, saturating at the numeric bounds
	/// instead of overflowing.
	public func saturatingAddition(_ rhs: Self) -> Self {
		let (partialValue, isOverflow) = addingReportingOverflow(rhs)

		if isOverflow {
			return partialValue.signum() >= 0 ? .min : .max
		} else {
			return partialValue
		}
	}
}
