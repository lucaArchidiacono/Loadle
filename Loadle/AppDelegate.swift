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

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		downloader = REST.Downloader()
		downloadManager = DownloadManager(downloader: downloader)
		return true
	}

	func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
		downloader.addBackgroundDownloadHandler(handler: completionHandler, identifier: identifier)
	}
}
