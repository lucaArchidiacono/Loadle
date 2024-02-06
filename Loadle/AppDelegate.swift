//
//  AppDelegate.swift
//  Loadle
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation
import REST
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, Observable {
    private var downloader: REST.Downloader!

    @Published var downloadManager: DownloadManager!

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        downloader = REST.Downloader()

        let loader = REST.Loader()
        downloadManager = DownloadManager(downloader: downloader, loader: loader)
        return true
    }

    func application(_: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        downloader.addBackgroundDownloadHandler(handler: completionHandler, identifier: identifier)
    }
}
