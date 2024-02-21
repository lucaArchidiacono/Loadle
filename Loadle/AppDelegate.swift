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
    let notificationService: NotificationService = .shared
    let downloadService: DownloadService = .shared
    let theme: Theme = .shared
    let preferences: UserPreferences = .shared

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

    func applicationDidEnterBackground(_: UIApplication) {
        #if DEBUG
            if downloadService.debuggingBackgroundTasks {
                exit(0)
            }
        #endif
    }

    func application(_: UIApplication, handleEventsForBackgroundURLSession _: String, completionHandler: @escaping () -> Void) {
        downloadService.addBackgroundCompletionHandler(handler: completionHandler)
        downloadService.addBackgroundCompletionHandler {
            NotificationService.shared.dispatchNotification(
                identifier: Constants.Notifications.download,
                title: L10n.notificationDownloadTitle,
                body: L10n.notificationDownloadBody
            )
        }
    }
}
