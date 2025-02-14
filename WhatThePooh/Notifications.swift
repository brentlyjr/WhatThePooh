//
//  Notifications.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/13/25.
//

import UserNotifications

class Notifications: ObservableObject {
    static let shared = Notifications()
    
    @Published var permissionGranted = false
    
    private init() {
        
    }

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

//    func requestNotificationPermissionIfNeeded() {
//        UNUserNotificationCenter.current().getNotificationSettings { settings in
//            switch settings.authorizationStatus {
//            case .notDetermined:
//                // Permission not asked yet, request it
//                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
//                    if granted {
//                        print("Notifications granted.")
//                    } else {
//                        print("Notifications denied.")
//                    }
//                }
//            case .denied:
//                print("Notifications were previously denied. User must enable them in Settings.")
//            case .authorized, .provisional, .ephemeral:
//                print("Notifications are already authorized.")
//            @unknown default:
//                print("Unknown notification authorization status.")
//            }
//        }
//    }

    func sendStatusChangeNotification(rideName: String, newStatus: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(rideName) Status Update"
        content.body = "The ride is now \(newStatus)."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}
