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
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

	func applicationDidEnterBackground(_ application: UIApplication) {
		#if DEBUG
		if REST.Downloader.shared.debuggingBackroundTasks {
				exit(0)
		}
		#endif
	}

    func application(_: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
		REST.Downloader.shared.addBackgroundCompletionHandler(handler: completionHandler)
		REST.Downloader.shared.addBackgroundCompletionHandler {
			NotificationService.shared.dispatchNotification(
				identifier: identifier,
				title: L10n.notificationDownloadTitle,
				body: L10n.notificationDownloadBody)
		}
    }
}
