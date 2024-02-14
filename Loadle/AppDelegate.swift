//
//  AppDelegate.swift
//  Loadle
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Foundation
import UIKit
import Constants
import Generator
import Environments

class AppDelegate: NSObject, UIApplicationDelegate {
	let notificationService: NotificationService = NotificationService.shared
	let downloadService: DownloadService = DownloadService.shared
	let theme: Theme = Theme.shared
	let preferences: UserPreferences = UserPreferences.shared

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
		downloadService.addBackgroundCompletionHandler {
			NotificationService.shared.dispatchNotification(
				identifier: Constants.Notifications.download,
				title: L10n.notificationDownloadTitle,
				body: L10n.notificationDownloadBody)
		}
    }
}
