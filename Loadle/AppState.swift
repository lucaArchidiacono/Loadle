//
//  AppState.swift
//  Loadle
//
//  Created by Luca Archidiacono on 29.04.2024.
//

import Foundation
import RevenueCat
import Constants
import Logger

@MainActor
@Observable
final class AppState {
	public var hasEntitlement: Bool = false

	static let shared: AppState = AppState()

	@ObservationIgnored
	private var observationTask: Task<Void, Never>?

	private init() {
		self.observationTask = Task { [weak self] in
			for await customerInfo in Purchases.shared.customerInfoStream {
				self?.hasEntitlement = customerInfo.entitlements[Constants.InApp.entitlementID]?.isActive ?? false
			}
		}
	}

	deinit {
		self.observationTask?.cancel()
	}

	public func checkEntitlement() async -> Bool {
		do {
			let customerInfo = try await Purchases.shared.customerInfo()
			return customerInfo.entitlements[Constants.InApp.entitlementID]?.isActive ?? false
		} catch {
			log(.error, error)
			return false
		}
	}
}
