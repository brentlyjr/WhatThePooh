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
    
    // Something we can look on later to determine if we should try to send notifications
    @Published var permissionGranted = false
    
    private init() { }
    
    // This really only needs to execute once on first app launch (assuming they
    // approve notifications). After this, it just confirms we have notifications enabled
    func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionGranted = settings.authorizationStatus == .authorized
            }
            
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    DispatchQueue.main.async {
                        self.permissionGranted = granted
                    }
                }
            }
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Authorization status: \(settings.authorizationStatus.rawValue)")
        }
    }
    
    // This is the code that generates our notification
    func sendStatusChangeNotification(rideName: String, newStatus: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(rideName) Status Update"
        content.body = "The ride is now \(newStatus)."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
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
