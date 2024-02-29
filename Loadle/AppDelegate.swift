//
//  AppDelegate.swift
//  Loadle
//
//  Created by Luca Archidiacono on 04.02.2024.
//

import Constants
import Environments
import Foundation
import Generator
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

    func applicationDidEnterBackground(_: UIApplication) {
        #if DEBUG
			if DownloadService.shared.debuggingBackgroundTasks {
                exit(0)
            }
        #endif
    }

    func application(_: UIApplication, handleEventsForBackgroundURLSession _: String, completionHandler: @escaping () -> Void) {
        DownloadService.shared.addBackgroundCompletionHandler(handler: completionHandler)
		DownloadService.shared.addBackgroundCompletionHandler {
            NotificationService.shared.dispatchNotification(
                identifier: Constants.Notifications.download,
                title: L10n.notificationDownloadTitle,
                body: L10n.notificationDownloadBody
            )
        }
    }
}
