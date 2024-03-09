//
//  NotificationService.swift
//  Loadle
//
//  Created by Luca Archidiacono on 11.02.2024.
//

import Foundation
import Logger
import UserNotifications

public class NotificationService {
    public static let shared = NotificationService()

    private init() {
        checkForPermissions()
    }

    private func checkForPermissions() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert, .sound]) { didAllow, _ in
                    if didAllow {
                        log(.verbose, "User did allow the retrieval of notifications.")
					} else {
                        log(.warning, "User did NOT allow the retrieval of notifications.")
					}
                }
            default: return
            }
        }
    }

    public func dispatchNotification(identifier: String, title: String, body: String) {
        let notificationCenter = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.add(request)
    }
}
