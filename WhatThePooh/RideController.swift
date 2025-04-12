//
//  RideController.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/2/25.
//

import Foundation
import Combine
import SwiftUI

struct RideResponse: Decodable {
    let liveData: [Ride]
}

class RideController: ObservableObject {
    // Singleton instance
    static let shared = RideController(notificationManager: Notifications.shared)
    
    // This is our published object that links to our RideView - Any updates to this
    // object will trigger a view update
    @Published var parkRideArray: [Ride] = []
    
    // An internal timer that will fetch updated statuses while we are in the foreground
    private var timer: Timer?
    
    // Persisted favorites – we only store the IDs.
    private let favoritesKey = "favoriteRides"
    private var favoriteIDs: Set<String> = []
    
    private weak var notificationManager: Notifications?
    
    private init(notificationManager: Notifications) {
        self.notificationManager = notificationManager
        loadFavorites()
    }
    
    // Retrieves all the entities (children) under a park - filters based on ATTRACTION
    // Stores them in a rideArray
    func fetchRidesForPark(for destinationID: String) -> Void {
        NetworkService.shared.performNetworkRequest(id: destinationID) { [weak self] data in
            guard let self = self else { return }
            
            guard let data = data else {
                print("\(ISO8601DateFormatter().string(from: Date())) - No data received for park query.")
                return
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(RideResponse.self, from: data)
                
                // Update parkRideArray on the main thread
                DispatchQueue.main.async {
                    // Decode the list of parks into our local park array
                    self.parkRideArray = response.liveData.filter { $0.entityType == .attraction }
                    
                    // Now fetch all the ride statuses for the list of rides for this park
                    self.updateRideStatus()
                }
                
            } catch {
                print("\(ISO8601DateFormatter().string(from: Date())) - Decoding error for our park: \(error)")
            }
        }
    }
    
    // This updates the ride status from the API. This updates our internal copy first and then
    // copies the data over to the main array to trigger a view refresh
    func updateRideStatus() -> Void {
        // Start all status updates asynchronously
        print("Fetching ride updates from RideController")
        for index in parkRideArray.indices {
            let ride = parkRideArray[index]
                        
            self.fetchStatus(for: ride) { [weak self] status, waitTime, lastUpdated in
                // Update visibleRideArray on the main thread
                DispatchQueue.main.async { [weak self] in

                    guard let self = self else { return }
                
                    self.parkRideArray[index].status = status
                    self.parkRideArray[index].waitTime = waitTime
                    self.parkRideArray[index].lastUpdated = lastUpdated
                    self.parkRideArray[index].oldStatus = ride.status

                    // Update favorite status
                    self.parkRideArray[index].isFavorited = self.favoriteIDs.contains(ride.id)

                    // Send notification about the status change
                    // self.sendNotificationOnStatusChange(for: self.parkRideArray[index])
                }
            }
        }
    }
    
    // Toggle the favorite state for a ride.
    func toggleFavorite(for ride: Ride) {
        guard let index = parkRideArray.firstIndex(where: { $0.id == ride.id }) else { return }
        parkRideArray[index].isFavorited.toggle()
        if parkRideArray[index].isFavorited {
            favoriteIDs.insert(ride.id)
        } else {
            favoriteIDs.remove(ride.id)
        }
        saveFavorites()
    }
    
    // This is the function that checks a ride's status and sends a notification if has changed
    private func sendNotificationOnStatusChange(for ride: Ride) {
        // If our ride status changed, and the value was not empty (IE, we had a previous stored state
        // Then we should be sending a status change notification.
        if ride.oldStatus != ride.status && ride.oldStatus != nil {
            // Use weak reference to avoid retain cycles
            weak var notifications = Notifications.shared
            notifications?.sendStatusChangeNotification(
                rideName: ride.name, 
                newStatus: ride.status ?? "Unknown",
                rideID: ride.id
            )
        }
    }
    
    // Load persisted favorite ride IDs from UserDefaults.
    private func loadFavorites() {
        if let storedIDs = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
            favoriteIDs = Set(storedIDs)
        }
    }
    
    // Save the current favorite ride IDs to UserDefaults.
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIDs), forKey: favoritesKey)
    }
    
    // Sets a timer to reguarly query ride statuses and update them
    func startStatusUpdates() -> Void {
        // Cancel any existing timer first
        stopStatusUpdates()
        
        // Create a new timer with a weak reference to self
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            AppLogger.shared.log("Timer started update")
            
            self.updateRideStatus()
        }
    }
    
    // Stop the status update timer
    func stopStatusUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    
    // Handle app entering background
    func applicationDidEnterBackground() {
        stopStatusUpdates()
    }
    
    // Handle app entering foreground
    func applicationWillEnterForeground() {
        startStatusUpdates()
    }

    private func fetchStatus(for entity: Ride, completion: @escaping (String?, Int?, String?) -> Void) {
        NetworkService.shared.performNetworkRequest(id: entity.id) { data in
            // No need to use self here, so we can remove the guard
            guard let data = data else {
                completion(nil, 0, nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let liveData = json["liveData"] as? [[String: Any]],
                   let firstLiveData = liveData.first {
                    let status = firstLiveData["status"] as? String ?? "Unknown"
                    let queue = firstLiveData["queue"] as? [String: Any]
                    let lastUpdated = firstLiveData["lastUpdated"] as? String ?? "No Date"
                    let standby = queue?["STANDBY"] as? [String: Any]
                    let waitTime = standby?["waitTime"] as? Int
                    completion(status, waitTime, lastUpdated)
                } else {
                    completion(nil, 0, nil)
                }
            } catch {
                print("\(ISO8601DateFormatter().string(from: Date())) - Error parsing status JSON: \(error)")
                completion(nil, 0, nil)
            }
        }
    }
    
    // Update the rides array with new data
    func updateRides(_ newRides: [Ride]) {
        // Create a mutable copy of the array
        var updatedRides = newRides
        
        // Preserve favorite status for existing rides
        for index in updatedRides.indices {
            if let existingRide = parkRideArray.first(where: { $0.id == updatedRides[index].id }) {
                updatedRides[index].isFavorited = existingRide.isFavorited
            }
        }
        
        // Update the array on the main thread
        DispatchQueue.main.async {
            self.parkRideArray = updatedRides
        }
    }
    
    // Check if a ride is favorited
    func isRideFavorited(id: String) -> Bool {
        return favoriteIDs.contains(id)
    }
}
