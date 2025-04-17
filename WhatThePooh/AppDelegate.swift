//
//  AppDelegate.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/13/25.
//

import SwiftUI
import BackgroundTasks
import os

class AppDelegate: UIResponder, UIApplicationDelegate {
    let logger = Logger(subsystem: "com.brentlyjr.WhatThePooh", category: "background")
    let refreshTaskIdentifier = "com.brentlyjr.WhatThePooh.refresh"

    // Empty function for now, does nothing
    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool
    {
        AppLogger.shared.log("willFinishLaunchingWithOptions() main launch")
        
        return true
    }
    
    // This function executes after our app has finished launching. Register our background task
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool
    {
        AppLogger.shared.log("Application main launch")
        
        let success = BGTaskScheduler.shared.register(forTaskWithIdentifier: self.refreshTaskIdentifier, using: nil) { task in
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }

        if !success {
            AppLogger.shared.log("Failed to register background task with identifier \(self.refreshTaskIdentifier)")
        }

        return true
    }
    
    // Schedule a BGAppRefreshTask for periodic background fetch
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: self.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60) // At least 2 min from now (used to be 15)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch let error as NSError {
            AppLogger.shared.log("Could not schedule app refresh: \(error)")
            AppLogger.shared.log("Could not schedule app refresh: \(error), \(error.userInfo)")
        }
    }
    
    private func handleAppRefreshTask(task: BGAppRefreshTask) {
        AppLogger.shared.log("Background task executing at \(Date())")
        
        task.expirationHandler = {
            AppLogger.shared.log("Background app refresh task expired before completion")
        }

        // Create a dispatch group to track all network requests
        let group = DispatchGroup()
        
        // Enter the group before starting the update
        group.enter()
        
        // Call updateAllParks() with a completion handler
        ParkRideManager.shared.updateAllParks(completion: {
            // Leave the group when all updates are complete
            group.leave()
        })

        // Wait for the group to complete or timeout after a reasonable time
        let timeout = DispatchTime.now() + .seconds(25) // 25 seconds max
        let result = group.wait(timeout: timeout)
        
        if result == .timedOut {
            AppLogger.shared.log("Background task timed out waiting for network requests")
        } else {
            AppLogger.shared.log("Background task completed successfully")
        }
        
        // Set ourselves up to run again
        scheduleAppRefresh()

        // Mark the task as completed
        task.setTaskCompleted(success: true)
    }
}
