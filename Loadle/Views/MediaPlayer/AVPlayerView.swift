//
//  AVPlayerView.swift
//  Loadle
//
//  Created by Luca Archidiacono on 22.03.2024.
//

import AVKit
import Environments
import Foundation
import Logger
import SwiftUI

struct AVPlayerView: UIViewControllerRepresentable {
    class CustomAVPlayerViewController: UIViewController, AVPictureInPictureControllerDelegate {
        class AVPlayerUIView: UIView {
            var player: AVPlayer? {
                get { return playerLayer.player }
                set { playerLayer.player = newValue }
            }

            var playerLayer: AVPlayerLayer {
                guard let playerLayer = layer as? AVPlayerLayer else {
                    fatalError("AssetPlayerView player layer must be an AVPlayerLayer")
                }
                return playerLayer
            }

            override static var layerClass: AnyClass {
                return AVPlayerLayer.self
            }
        }

        private var pipController: AVPictureInPictureController!

        var playerItem: PlayerItemWrapper

        lazy var playerView: AVPlayerUIView = {
            let view = AVPlayerUIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()

        init(playerItem: PlayerItemWrapper) {
            self.playerItem = playerItem
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            view.addSubview(playerView)

            NSLayoutConstraint.activate([
                playerView.topAnchor.constraint(equalTo: view.topAnchor),
                playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        public func setup() {
            // Ensure PiP is supported by current device.
            if AVPictureInPictureController.isPictureInPictureSupported() {
                // Create a new controller, passing the reference to the AVPlayerLayer.
                pipController = AVPictureInPictureController(playerLayer: playerView.playerLayer)
                pipController.delegate = self
            }
        }

        func pictureInPictureControllerWillStopPictureInPicture(_: AVPictureInPictureController) {
            log(.debug, "Will stop picture in picture")
        }

        func pictureInPictureController(_: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
            log(.debug, "Restore UI before PiP Stops")
            completionHandler(true)
        }
    }

    var playerItem: PlayerItemWrapper
    var player: AVPlayer

    func makeUIViewController(context _: Context) -> CustomAVPlayerViewController {
        let viewController = CustomAVPlayerViewController(playerItem: playerItem)
        viewController.playerView.player = player
        viewController.setup()
        return viewController
    }

    func updateUIViewController(_ uiViewController: CustomAVPlayerViewController, context _: Context) {
        uiViewController.playerItem = playerItem
        uiViewController.playerView.player = player
    }
}
