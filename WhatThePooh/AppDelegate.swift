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
    var rideController = RideController()
    var notificationManager = Notifications.shared
    let logger = Logger(subsystem: "com.brentlyjr.WhatThePooh", category: "background")
    
    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool
    {
        logger.log("willFinishLaunchingWithOptions() main launch")
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.log("Application main launch")
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.brentlyjr.WhatThePooh.refresh", using: nil) { task in
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
        return true
    }
    
    private func registerBackgroundTasks() {
        let refreshTaskIdentifier = "com.brentlyjr.WhatThePooh.refresh"
        
        let success = BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { task in
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
        
        if !success {
            logger.error("Failed to register background task with identifier \(refreshTaskIdentifier)")
        }
    }
    
    // Schedule a BGAppRefreshTask for periodic background fetch
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.brentlyjr.WhatThePooh.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // At least 1 min from now (used to be 15)
        
        do {
            logger.log("Scheduling refresh task!")
            try BGTaskScheduler.shared.submit(request)
            logger.log("Task scheduled, we think!")
        } catch let error as NSError {
            logger.log("Could not schedule app refresh: \(error)")
            logger.error("Could not schedule app refresh: \(error), \(error.userInfo)")
        }
    }
    
    
    private func handleAppRefreshTask(task: BGAppRefreshTask) {
        logger.info("Background app refresh task started")
        
        task.expirationHandler = {
            self.logger.error("Background app refresh task expired before completion")
        }

        logger.log("Firing notification at: \(Date())")

        // Simulate fetching ride statuses — replace with actual API call
        //       fetchUpdatedRideStatuses()

        notificationManager.sendStatusChangeNotification(rideName: "Star Wars: Rise of the Resistance", newStatus: "Down")

        scheduleAppRefresh()

        task.setTaskCompleted(success: true)
    }
}
