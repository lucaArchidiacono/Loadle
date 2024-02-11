//
//  ServiceView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import SwiftUI

struct ServiceView: View {
	@EnvironmentObject private var preferences: UserPreferences
	@EnvironmentObject private var theme: Theme

	@Environment(Router.self) private var router: Router

	let service: Service

	var body: some View {
		service.text
	}
}
