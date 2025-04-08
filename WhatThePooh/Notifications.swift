//
//  Notifications.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/13/25.
//

import UserNotifications


// Define a notification name for opening ride details
extension Notification.Name {
    static let openRideDetails = Notification.Name("openRideDetails")
}

class Notifications: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    // Singleton of Notification class
    static let shared = Notifications()
    
    // This is our main notification array. This is a list of the rides across
    // all parks that are "favorited" so we can monitor their status and
    // send notifications for them on status change
    private var rideNotificationArray: [Ride] = []

    // Published state that determines if we can send notifications
    @Published private(set) var permissionGranted = false
    
    private override init() {
        super.init()
        
        // Check initial permission status
        Task {
            await checkPermissionStatus()
        }
        
        // Set this class as the delegate for UNUserNotificationCenter
        UNUserNotificationCenter.current().delegate = self
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
    func sendStatusChangeNotification(rideName: String, newStatus: String, rideID: String) {
        guard permissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(rideName) Status Update"
        content.body = "The ride is now \(newStatus)."
        content.sound = .default
        
        // Add the ride ID to the notification's userInfo
        content.userInfo = ["rideID": rideID]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let currentDateTime = dateFormatter.string(from: Date())
        
        print(" ** [\(currentDateTime)] Ride \(rideName) status updated to \(newStatus). Sending notification. **")
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
        // Show the notification as a banner with sound
        completionHandler([.banner, .sound])
    }
    
    // Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Extract the ride ID from the notification
        if let rideID = userInfo["rideID"] as? String {
            // Post a notification that your app can observe
            NotificationCenter.default.post(name: .openRideDetails, 
                                         object: nil, 
                                         userInfo: ["rideID": rideID])
            
            print("Notification tapped for ride ID: \(rideID)")
        }
        
        completionHandler()
    }
}
