//
//  NotificationDelegate.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/14/25.
//
//  Delegate is required to show the notifications while the app is in the foreground.
//  Otherwise, it will only give ride status changes while the app is backgrounded
//

import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification as a banner with sound, even when the app is in the foreground
        completionHandler([.banner, .sound])
    }
}
