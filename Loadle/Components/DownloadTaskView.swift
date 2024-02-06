//
//  DownloadTaskView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 05.02.2024.
//

import Foundation
import REST
import SwiftUI

struct DownloadTaskView: View {
    let task: REST.DownloadTask

    @State private var progress: Double = 0.0

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.url.lastPathComponent)
                    .font(.headline)

                ProgressBar(progress: progress)
                    .frame(height: 10)

                HStack {
                    Button("Cancel") {
                        task.cancel()
                    }
                    .foregroundColor(.red)

                    Spacer()

                    Button("Retry") {
                        //						task.retry()
                    }
                    .foregroundColor(.blue)
                    .disabled(task.state != .failed)
                }
            }
        }
        .padding()
        .onAppear {
            task.onProgress = { newProgress in
                DispatchQueue.main.async {
                    self.progress = newProgress
                }
            }
        }
    }
}
