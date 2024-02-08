//
//  AppDelegate.swift
//  Loadle
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation
import REST
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var downloadManager: DownloadManager!

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		downloadManager = DownloadManager.shared
        return true
    }

    func application(_: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
		downloadManager.addBackgroundDownloadHandler(handler: completionHandler, identifier: identifier)
    }
}
