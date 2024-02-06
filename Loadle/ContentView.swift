//
//  ContentView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.01.2024.
//

import Logger
import REST
import SwiftData
import SwiftUI

struct ContentView: View {
  @Environment(DownloadManager.self) private var downloadManager
  @EnvironmentObject private var preferences: UserPreferences

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
            if let url = URL(string: url) {
              downloadManager.startDownload(using: url, preferences: preferences)
            } else {
              log(.error, "No real url")
            }
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
        })
      .navigationBarTitle("Download Manager")
    }
    .sheet(isPresented: $isSettingsVisible) {
      SettingsView()
    }
  }
}
