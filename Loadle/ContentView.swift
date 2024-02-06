//
//  ContentView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
	@Environment(DownloadManager.self) private var downloadManager

	@State private var url: String = ""
	@State private var isSettingsVisible: Bool = false

	var body: some View {
		NavigationView {
			VStack {
				HStack {
					TextField("Enter URL", text: $url)
						.textFieldStyle(RoundedBorderTextFieldStyle())
						.padding()

					Button(action: {
						startDownload()
					}) {
						Text("Download")
							.padding(.horizontal)
							.padding(.vertical, 10)
							.background(Color.blue)
							.foregroundColor(Color.white)
							.cornerRadius(8)
					}
				}

				List(downloadManager.downloads, id: \.id) { task in
					DownloadTaskView(task: task)
				}
				.listStyle(PlainListStyle())

				Spacer()
			}
			.navigationBarItems(trailing:
									Button(action: {
				isSettingsVisible.toggle()
			}) {
				Image(systemName: "gear")
					.font(.title)
			}
			)
			.navigationBarTitle("Download Manager")
		}
		.sheet(isPresented: $isSettingsVisible) {
			SettingsView()
		}
	}
}

#Preview {
    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
}
