//
//  WhatThePoohApp.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI
import UserNotifications

@main
struct WhatThePoohApp: App {

    @StateObject private var notificationManager = Notifications.shared
    
    private let notificationDelegate = NotificationDelegate()

    init() {
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate // Set the delegate here
        
        // Request notification permissions
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear() {
                    notificationManager.requestNotificationPermissionIfNeeded()
                }
        }
    }
}
