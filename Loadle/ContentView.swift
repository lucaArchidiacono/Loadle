//
//  ContentView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import Logger
import SwiftUI

struct ContentView: View {
	@Environment(\.openWindow) private var openWindow
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	@EnvironmentObject private var theme: Theme
	@EnvironmentObject private var preferences: UserPreferences

	@Binding var selectedTab: Tab
	@Binding var router: Router

	@State var iosTabs = iOSTabs.shared
	@State var sidebarTabs = SidebarTabs.shared

	var body: some View {
		if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac {
			sidebarView
		} else {
			tabBarView
		}
	}

	var availableTabs: [Tab] {
		if UIDevice.current.userInterfaceIdiom == .phone || horizontalSizeClass == .compact {
			return iosTabs.tabs
		} else {
			return sidebarTabs.tabs.map { $0 }
		}
	}

	@ViewBuilder
	var sidebarView: some View {
		NavigationSplitView {
			List(selection: .init(get: {
				Optional(selectedTab)
			}, set: { newTab in
				if let newTab {
					selectedTab = newTab
				}
			})) {
				ForEach(availableTabs) { tab in
					tab.label
				}
			}
		} detail: {
			selectedTab.makeContentView()
		}
	}

	@ViewBuilder
	var tabBarView: some View {
		TabView(selection: .init(get: {
			selectedTab
		}, set: { newTab in
			selectedTab = newTab
		})) {
			ForEach(availableTabs) { tab in
				tab.makeContentView()
					.tabItem {
						tab.label
					}
					.tag(tab)
					.toolbarBackground(theme.primaryBackgroundColor.opacity(0.30), for: .tabBar)
			}
		}
	}
}

#Preview {
	ContentView(selectedTab: .constant(.home), router: .constant(Router()))
		.environmentObject(Theme.shared)
		.environmentObject(UserPreferences.shared)
}
