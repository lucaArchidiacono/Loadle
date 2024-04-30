//
//  AsyncImageProvider.swift
//
//
//  Created by Luca Archidiacono on 20.02.2024.
//

import Foundation
import Logger
import SwiftUI

public struct AsyncImageProvider<Content>: View where Content: View {
    @State private var image: Image?
    @State private var isLoading = false

    private let itemProvider: NSItemProvider?
    private let placeholder: Image

    @ViewBuilder private var content: (Image) -> Content

    public init(itemProvider: NSItemProvider?, placeholder: Image, content: @escaping (Image) -> Content) {
        self.itemProvider = itemProvider
        self.placeholder = placeholder
        self.content = content
    }

    public var body: some View {
        Group {
            if isLoading {
                content(Image(uiImage: UIImage()))
            } else {
                if let image = image {
                    content(image)
                } else {
                    content(placeholder)
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard let itemProvider, !isLoading else { return }
        isLoading = true

        _ = itemProvider.loadTransferable(type: Data.self, completionHandler: { result in
            switch result {
            case let .success(data):
                if let uiImage = UIImage(data: data) {
                    self.image = Image(uiImage: uiImage)
                }
            case .failure:
                break
            }
            isLoading = false
        })
    }
}
