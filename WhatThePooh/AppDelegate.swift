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
        logger.log("willFinishLaunchingWithOptions() main launch")
        
        return true
    }
    
    // This function executes after our app has finished launching. Register our background task
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        logger.log("Application main launch")
        
        let success = BGTaskScheduler.shared.register(forTaskWithIdentifier: self.refreshTaskIdentifier, using: nil) { task in
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }

        if !success {
            logger.error("Failed to register background task with identifier \(self.refreshTaskIdentifier)")
        }

        return true
    }
    
    // this code is
//    private func registerBackgroundTasks() {
//        let refreshTaskIdentifier = "com.brentlyjr.WhatThePooh.refresh"
//        
//        let success = BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { task in
//            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
//        }
//        
//        if !success {
//            logger.error("Failed to register background task with identifier \(refreshTaskIdentifier)")
//        }
//    }
    
    // Schedule a BGAppRefreshTask for periodic background fetch
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: self.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60) // At least 2 min from now (used to be 15)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.log("\(self.refreshTaskIdentifier) - task scheduled!")
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

//    TODO: Need to actually call code to check and send notifications, if needed
        // Simulate fetching ride statuses — replace with actual API call
        //       fetchUpdatedRideStatuses()

        // notificationManager.sendStatusChangeNotification(rideName: "Star Wars: Rise of the Resistance", newStatus: "Down")

        // Set ourselves up to run again
        scheduleAppRefresh()

        task.setTaskCompleted(success: true)
    }
    
    // Handle app entering background
    func applicationDidEnterBackground(_ application: UIApplication) {
        logger.log("Application did enter background")
        RideController.shared.applicationDidEnterBackground()
    }
    
    // Handle app entering foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.log("Application will enter foreground")
        RideController.shared.applicationWillEnterForeground()
    }
}
