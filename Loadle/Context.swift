//
//  Context.swift
//  Loadle
//
//  Created by Luca Archidiacono on 28.04.2024.
//

import Foundation
import RevenueCat
import Constants

@MainActor
@Observable
final class Context {
	static let shared: Context = Context()

	private init() {}

	func hasPlusSubscription() {
		Task {
			// Using Swift Concurrency
			let customerInfo = try await Purchases.shared.customerInfo()
			if customerInfo.entitlements.all[Constants.InApp.entitlementID]?.isActive == true {
				// User is "premium"
			}
			// Using Completion Blocks
			Purchases.shared.getCustomerInfo { (customerInfo, error) in
				if customerInfo?.entitlements.all[<your_entitlement_id>]?.isActive == true {
					// User is "premium"
				}
			}
		}
	}
}
