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
import Logger
import UIKit
import RevenueCat

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		NotificationService.shared.checkForPermissions()
		
		Purchases.logLevel = .debug
		Purchases.configure(
			with: Configuration.builder(withAPIKey: Constants.InApp.apiKey)
				.build()
		)

        return true
    }

    func application(_: UIApplication, handleEventsForBackgroundURLSession _: String, completionHandler: @escaping () -> Void) {
        DownloadService.shared.addBackgroundCompletionHandler(completion: completionHandler)
		DownloadService.shared.addBackgroundCompletionHandler {
            NotificationService.shared.dispatchNotification(
                identifier: Constants.Notifications.download,
                title: L10n.notificationDownloadTitle,
                body: L10n.notificationDownloadBody
            )
        }
    }
}
