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
    // Initialize our core services
    @StateObject private var notificationManager = Notifications.shared
    
    // Initialize app delegate for background tasks
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Configure notification center
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationManager
        
        // Request notification permissions
        Task {
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                print("Notification permission granted: \(granted)")
            } catch {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
                .onAppear {
                    // Ensure notification permissions are requested
                    notificationManager.requestNotificationPermissionIfNeeded()
                    // Schedule background refresh
                    appDelegate.scheduleAppRefresh()
                }
        }
    }
}
