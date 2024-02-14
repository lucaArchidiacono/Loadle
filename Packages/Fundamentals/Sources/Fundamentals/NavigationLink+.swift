//
//  NavigationLink+.swift
//  Loadle
//
//  Created by Luca Archidiacono on 07.02.2024.
//

import Foundation
import SwiftUI

public extension NavigationLink where Label: View, Destination == EmptyView {
	/// Useful in cases where a `NavigationLink` is needed but there should not be
	/// a destination. (e.g.  we present a sheet programmatically but we
	/// still want to show a Disclosure Indicator).
	static func empty(label: @escaping () -> Label, onTap: @escaping () -> Void) -> some View {
		self.init(destination: EmptyView()) { label() }.onTapGesture { onTap() }
	}
}
