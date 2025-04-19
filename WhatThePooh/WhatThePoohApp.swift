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
    @StateObject private var viewModel = SharedViewModel()
    @StateObject private var parkStore = ParkStore.shared
    @StateObject private var parkRideManager = ParkRideManager(notificationManager: Notifications.shared, sharedViewModel: SharedViewModel())
    
    // Initialize app delegate for background tasks
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(notificationManager)
                    .environmentObject(viewModel)
                    .environmentObject(parkStore)
                    .environmentObject(parkRideManager)
                
                if !viewModel.hasSeenSplash {
                    SplashScreenView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Initialize ParkRideManager with park IDs from ParkStore
                let parkIds = parkStore.parks.map { $0.id }
                parkRideManager.initialize(with: parkIds)
                
                // Set up notification center delegate
                UNUserNotificationCenter.current().delegate = notificationManager
                
                // Ensure notification permissions are requested
                notificationManager.requestNotificationPermissionIfNeeded()
                
                // Update parkRideManager with the correct viewModel
                parkRideManager.updateSharedViewModel(viewModel)
                
                // Inject parkRideManager into AppDelegate
                appDelegate.parkRideManager = parkRideManager
                
                // Schedule background refresh
                appDelegate.scheduleAppRefresh()
                
                // Mark splash screen as seen after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        viewModel.hasSeenSplash = true
                    }
                }
            }
        }
    }
}
