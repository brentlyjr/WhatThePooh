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
    @Published var visibleRideArray: [Ride] = []

    // This is our internal ride array. This spans all of our parks and will allow us
    // to get the updated status for all rides that we may have favorited
    private var parkRideArray: [Ride] = []

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
    func fetchRidesForPark(for destinationID: String, completion: @escaping () -> Void) {
        performNetworkRequest(id: destinationID) { [weak self] data in
            guard let self = self else { return }
            
            guard let data = data else {
                print("No data received for park query.")
                completion()
                return
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(RideResponse.self, from: data)
                
                // Decode the list of parks into our local park array
                self.parkRideArray = response.liveData.filter { $0.entityType == .attraction }
                
                // Execute our completion handler so we can chain funtions together
                completion()

            } catch {
                print("Decoding error for our park: \(error)")
                completion()
            }
        }
    }
    

    // This updates the ride status from the API. This updates our internal copy first and then
    // copies the data over to the main array to trigger a view refresh
    func updateRideStatus() -> Void {
        // Start all status updates asynchronously
        for index in parkRideArray.indices {
            let ride = parkRideArray[index]
            
            // Capture the index in a local variable to avoid potential issues with the closure
            let currentIndex = index
            
            self.fetchStatus(for: ride) { [weak self] status, waitTime, lastUpdated in
                guard let self = self else { return }
                
                    // Batch update all properties atomically
                    self.parkRideArray[currentIndex].status = status
                    self.parkRideArray[currentIndex].waitTime = waitTime
                    self.parkRideArray[currentIndex].lastUpdated = lastUpdated
                    self.parkRideArray[currentIndex].oldStatus = ride.status
                    
                    // Update favorite status
                    let rideID = self.parkRideArray[currentIndex].id
                    self.parkRideArray[currentIndex].isFavorited = self.favoriteIDs.contains(rideID)

                    // Send notification about the status change
                    self.sendNotificationOnStatusChange(for: self.parkRideArray[currentIndex])
                    
                    // Update visibleRideArray on the main thread
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        // If visibleRideArray doesn't have the ride (first time) then add it
                        if self.visibleRideArray.count != self.parkRideArray.count {
                            // For first time, simply replace it with the updated internal array
                            self.visibleRideArray = self.parkRideArray
                        } else {
                            // Otherwise, update the existing ride at the same index
                            self.visibleRideArray[currentIndex].status = self.parkRideArray[currentIndex].status
                            self.visibleRideArray[currentIndex].waitTime = self.parkRideArray[currentIndex].waitTime
                            self.visibleRideArray[currentIndex].lastUpdated = self.parkRideArray[currentIndex].lastUpdated
                            self.visibleRideArray[currentIndex].oldStatus = self.parkRideArray[currentIndex].oldStatus
                            self.visibleRideArray[currentIndex].isFavorited = self.parkRideArray[currentIndex].isFavorited
                        }
                        
                        // Notify SwiftUI that we've updated the observable object
                        self.objectWillChange.send()
                    }
                }
        }
    }

    
    // Toggle the favorite state for a ride.
    func toggleFavorite(for ride: Ride) {
        guard let index = visibleRideArray.firstIndex(where: { $0.id == ride.id }) else { return }
        visibleRideArray[index].isFavorited.toggle()
        if visibleRideArray[index].isFavorited {
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
            print("Notification check for ride \(ride.name)")
            print(" --> Previous Status: \(String(describing: ride.oldStatus))")
            print(" --> Current Status: \(String(describing: ride.status))")
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
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
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
        performNetworkRequest(id: entity.id) { [weak self] data in
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
                print("Error parsing status JSON: \(error)")
                completion(nil, 0, nil)
            }
        }
    }
    
    func performNetworkRequest(id: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: "https://api.themeparks.wiki/v1/entity/\(id)/live") else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(data)
        }.resume()
    }
}
