//
//  AppDelegate.swift
//  Loadle
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation
import UIKit
import Environments

class AppDelegate: NSObject, UIApplicationDelegate {
	let notificationService: NotificationService = NotificationService.shared
	let downloadService: DownloadService = DownloadService.shared

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

	func applicationDidEnterBackground(_ application: UIApplication) {
		#if DEBUG
		if downloadService.debuggingBackgroundTasks {
				exit(0)
		}
		#endif
	}

    func application(_: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
		downloadService.addBackgroundCompletionHandler(handler: completionHandler)
    }
}
