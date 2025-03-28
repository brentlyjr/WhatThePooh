//
//  Notifications.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/13/25.
//

import UserNotifications

class Notifications: ObservableObject {

    // Singleton of Notification class
    static let shared = Notifications()
    
    // Published state
    @Published private(set) var permissionGranted = false
    
    private init() {
        // Check initial permission status
        Task {
            await checkPermissionStatus()
        }
    }
    
    // Check current permission status
    private func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        DispatchQueue.main.async {
            self.permissionGranted = settings.authorizationStatus == .authorized
        }
    }
    
    // Request notification permissions if needed
    func requestNotificationPermissionIfNeeded() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            
            if settings.authorizationStatus == .notDetermined {
                do {
                    let granted = try await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .badge, .sound])
                    DispatchQueue.main.async {
                        self.permissionGranted = granted
                    }
                } catch {
                    print("Error requesting notification permission: \(error.localizedDescription)")
                }
            } else {
                await checkPermissionStatus()
            }
        }
    }
    
    // Send a status change notification
    func sendStatusChangeNotification(rideName: String, newStatus: String) {
        guard permissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(rideName) Status Update"
        content.body = "The ride is now \(newStatus)."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Allow foreground notifications while app is running
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
