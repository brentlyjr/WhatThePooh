//
//  ParkRideManager.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 4/9/25.
//

import Foundation
import Combine

struct SimpleParkRide {
    let parkId: String
    let rideId: String
    let name: String
    let waitTime: Int?
    let lastUpdated: Date
    let status: String?
    let prevStatus: String?  // New field to track previous status
}

class ParkRideManager: ObservableObject {
    // Dictionary to store park IDs and their array of SimpleParkRide
    private var parkRideArray: [String: [SimpleParkRide]] = [:]
    
    // Published property to notify observers when rides are updated
    @Published private(set) var lastUpdated: Date = Date()
    
    // Flag to track if the manager has been initialized
    private var isInitialized = false
    
    // Timer for periodic updates
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 60  // 2 minutes
    
    // Weak reference to notification manager to avoid retain cycles
    private weak var notificationManager: Notifications?
    
    // Reference to SharedViewModel for settings
    private var sharedViewModel: SharedViewModel
    
    // Public initializer for dependency injection
    init(notificationManager: Notifications, sharedViewModel: SharedViewModel) {
        self.notificationManager = notificationManager
        self.sharedViewModel = sharedViewModel
    }
    
    // Update the SharedViewModel reference
    func updateSharedViewModel(_ viewModel: SharedViewModel) {
        self.sharedViewModel = viewModel
    }
    
    // Initialize the ParkRideManager with park IDs
    func initialize(with parkIds: [String]) {
        // Only initialize once
        guard !isInitialized else {
            print("ParkRideManager already initialized")
            return
        }
        
        // Set up the parks with empty ride arrays
        for parkId in parkIds {
            parkRideArray[parkId] = []
        }
        
        isInitialized = true
        
        // Load rides for all parks
        for parkId in parkIds {
            updateRidesForPark(for: parkId)
        }
        
        // Start the update timer
        startUpdateTimer()
    }
    
    // Start the timer for periodic updates
    func startUpdateTimer() {
        // Cancel any existing timer
        updateTimer?.invalidate()
        
        // Create a new timer that fires every updateInterval seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            AppLogger.shared.log("Timer triggering update")
            self?.updateAllParks()
        }
        
        print("Started update timer with interval of \(updateInterval) seconds")
    }
    
    // Stop the update timer
    func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
        print("Stopped update timer")
    }
    
    // Update all parks
    func updateAllParks(completion: (() -> Void)? = nil) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let currentDateTime = dateFormatter.string(from: Date())
        print("Updating status' for all parks at \(currentDateTime)")
        AppLogger.shared.log("Updating status' for all parks")

        // Create a dispatch group to track all network requests
        let group = DispatchGroup()
        
        for parkId in parkRideArray.keys {
            group.enter()
            updateRidesForPark(for: parkId) {
                group.leave()
            }
        }
        
        // When all requests are done, call the completion handler
        group.notify(queue: .main) {
            completion?()
            print("Done with dispatch group")
            AppLogger.shared.log("Done with dispatch group")
        }
    }
    
    func updateRidesForPark(for parkId: String, completion: (() -> Void)? = nil) {
        // Make a network request to fetch the latest ride data for the specified park
        NetworkService.shared.performNetworkRequest(id: parkId) { [weak self] data in
            // Use weak self to avoid retain cycles
            guard let self = self else {
                completion?()
                return
            }
            
            // Check if we received valid data from the network request
            guard let data = data else {
                print("No data received for park \(parkId)")
                completion?()
                return
            }
            
            do {
                // Parse the JSON response into a dictionary and extract the liveData array
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let liveData = json["liveData"] as? [[String: Any]] {
                    
                    // Convert the raw JSON data into SimpleParkRide objects
                    let rides = self.parseRides(from: liveData, for: parkId)
                    
                    // Compare with previous ride data to track status changes
                    // This adds the previous status to each ride for change detection
                    let updatedRides = self .updateRidesWithPreviousStatus(rides, for: parkId)
                    
                    // Store the updated rides in our internal data structure
                    // This also updates the RideController if this is the currently selected park
                    self.updateRides(updatedRides, for: parkId)
                    
                    // Get park information for logging and notification purposes
                    let currentPark = ParkStore.shared.getPark(withId: parkId)
                    let parkName = currentPark?.name ?? "Unknown Park"
                    let isFavoritedPark = ParkStore.shared.isParkFavorited(id: parkId)
                    let parkDisplayName = isFavoritedPark ? "\(parkName) (*)" : parkName
                    let parkOpen = currentPark?.isOpen ?? false

                    // Check each ride for status changes and send notifications if needed
                    for ride in updatedRides {
                        // Only process rides where the status has changed
                        if let prevStatus = ride.prevStatus,
                           let currentStatus = ride.status,
                           prevStatus != currentStatus {
                            // Format park status for logging
                            let parkStatus = parkOpen ? "(Park Open)" : "(Park Closed)"
                            print("Status changed for ride '\(ride.name)' at \(parkDisplayName): \(prevStatus) -> \(currentStatus). \(parkStatus)")
                            
                            // Is this a favoritedRide
                            let isFavoritedRide = RideController.shared.isRideFavorited(id: ride.rideId)
                            
                            // Only send notifications for favorited parks AND either:
                            // 1. The ride is favorited, OR
                            // 2. Chatty notifications are enabled
                            if (isFavoritedPark && (isFavoritedRide || self.sharedViewModel.chattyNotifications)) {
                                // Log the status change
                                AppLogger.shared.log("Ride: '\(ride.name)' at \(parkDisplayName): \(prevStatus) -> \(currentStatus)")
                                print("*** Sending notification for ride '\(ride.name)' at \(parkDisplayName): \(prevStatus) -> \(currentStatus).")
                                
                                // Send a notification to the user about the status change
                                self.notificationManager?.sendStatusChangeNotification(
                                    rideName: ride.name,
                                    newStatus: currentStatus,
                                    rideID: ride.rideId,
                                    parkName: parkName
                                )
                            }
                        }
                    }
                }
            } catch {
                // Log any errors that occur during JSON parsing
                print("Error parsing ride data for park \(parkId): \(error)")
            }
            
            // Call the completion handler when the update is finished
            completion?()
        }
    }
    
    private func parseRides(from liveData: [[String: Any]], for parkId: String) -> [SimpleParkRide] {
        return liveData.compactMap { rideData -> SimpleParkRide? in
            guard let entityType = rideData["entityType"] as? String,
                  entityType == "ATTRACTION",
                  let id = rideData["id"] as? String,
                  let name = rideData["name"] as? String,
                  let status = rideData["status"] as? String,
                  let lastUpdatedStr = rideData["lastUpdated"] as? String,
                  let lastUpdated = ISO8601DateFormatter().date(from: lastUpdatedStr) else {
                return nil
            }
            
            var waitTime = nil as Int?
            if status == "OPERATING" {
                // Extract wait time from queue->STANDBY->waitTime
                waitTime = extractWaitTime(from: rideData)
            }
            
            return SimpleParkRide(
                parkId: parkId,
                rideId: id,
                name: name,
                waitTime: waitTime,
                lastUpdated: lastUpdated,
                status: status,
                prevStatus: nil  // Initial parse always has nil prevStatus
            )
        }
    }
    
    private func extractWaitTime(from rideData: [String: Any]) -> Int? {
        if let queue = rideData["queue"] as? [String: Any],
           let standby = queue["STANDBY"] as? [String: Any],
           let waitTime = standby["waitTime"] as? Int {
            return waitTime
        }
        return nil
    }
    
    private func updateRides(_ rides: [SimpleParkRide], for parkId: String) {
        parkRideArray[parkId] = rides
        
        // Update the lastUpdated timestamp to notify observers
        DispatchQueue.main.async {
            self.lastUpdated = Date()
        }
        
        // TODO: oh, the copy stuff is here, this is what would check background and foreground.
        // or should we move this copy stuff out into the main loop?
        
        // Update RideController if this is the selected park (this is checked inside function)
        updateRideController(for: parkId, with: rides)
    }
    
    private func convertToRide(_ simpleRide: SimpleParkRide) -> Ride {
        return Ride(
            id: simpleRide.rideId,
            name: simpleRide.name,
            entityType: .attraction,
            status: simpleRide.status,
            waitTime: simpleRide.waitTime,
            lastUpdated: ISO8601DateFormatter().string(from: simpleRide.lastUpdated),
            isFavorited: RideController.shared.isRideFavorited(id: simpleRide.rideId)
        )
    }
    
    private func updateRideController(for parkId: String, with rides: [SimpleParkRide]) {
        // Only update if this is the currently selected park
        if parkId == ParkStore.shared.currentSelectedPark?.id {
            let convertedRides = rides.map { convertToRide($0) }
            
            // Update on main thread since this affects UI
            DispatchQueue.main.async {
                RideController.shared.updateRides(convertedRides)
            }
        }
    }
    
    private func updateRidesWithPreviousStatus(_ newRides: [SimpleParkRide], for parkId: String) -> [SimpleParkRide] {
        // Create a dictionary of existing rides for easy lookup
        let existingRides = parkRideArray[parkId] ?? []
        let existingRideDict = Dictionary(uniqueKeysWithValues: existingRides.map { ($0.rideId, $0) })
        
        // Update prevStatus for each new ride
        return newRides.map { ride -> SimpleParkRide in
            if let existingRide = existingRideDict[ride.rideId] {
                // Create new SimpleParkRide with the previous status
                return SimpleParkRide(
                    parkId: ride.parkId,
                    rideId: ride.rideId,
                    name: ride.name,
                    waitTime: ride.waitTime,
                    lastUpdated: ride.lastUpdated,
                    status: ride.status,
                    prevStatus: existingRide.status
                )
            } else {
                // For new rides, prevStatus is nil
                return SimpleParkRide(
                    parkId: ride.parkId,
                    rideId: ride.rideId,
                    name: ride.name,
                    waitTime: ride.waitTime,
                    lastUpdated: ride.lastUpdated,
                    status: ride.status,
                    prevStatus: nil
                )
            }
        }
    }
    
    // Get all park IDs currently managed by ParkRideManager
    func getAllParkIds() -> [String] {
        return Array(parkRideArray.keys)
    }
    
    // Get all Rides for a specific park
    func getRides(for parkId: String) -> [SimpleParkRide] {
        return parkRideArray[parkId] ?? []
    }
} 
