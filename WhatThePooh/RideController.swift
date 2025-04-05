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
        performNetworkRequest(id: destinationID) { data in
            guard let data = data else {
                print("No data received for park query.")
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
            }
        }
    }
    
    // This updates the ride status from the API. This just updates our internal copy
    func updateRideStatus_synchronous(completion: @escaping () -> Void) {
        
        // Setting up a completion block around our ride query
        let dispatchGroup = DispatchGroup()
        
        for index in parkRideArray.indices {
            let ride = parkRideArray[index]

            dispatchGroup.enter()

            self.fetchStatus(for: ride) { [weak self] status, waitTime, lastUpdated in
                self?.parkRideArray[index].status = status
                self?.parkRideArray[index].waitTime = waitTime
                self?.parkRideArray[index].lastUpdated = lastUpdated
                
                // We are basically keeping the old status so we can compare to see if it has changed later
                self?.parkRideArray[index].oldStatus = ride.status

                // Basicaly make sure the favorite status matches what our cache has (replaces its own function)
                if let rideID = self?.parkRideArray[index].id {
                    self?.parkRideArray[index].isFavorited = self?.favoriteIDs.contains(rideID) ?? false
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .global()) {
            completion()
        }
    }

    // This updates the ride status from the API. This updates our internal copy first and then
    // copies the data over to the main array to trigger a view refresh
    func updateRideStatus(completion: @escaping () -> Void) {
        for index in parkRideArray.indices {
            let ride = parkRideArray[index]
            
            self.fetchStatus(for: ride) { [weak self] status, waitTime, lastUpdated in
                guard let self = self else { return }
                
                // Update internal copy
                self.parkRideArray[index].status = status
                self.parkRideArray[index].waitTime = waitTime
                self.parkRideArray[index].lastUpdated = lastUpdated
                self.parkRideArray[index].oldStatus = ride.status
                
                // Update favorite status
                let rideID = self.parkRideArray[index].id
                self.parkRideArray[index].isFavorited = self.favoriteIDs.contains(rideID)
                
                sendNotificationOnStatusChange(for: self.parkRideArray[index])
                
                // Update visibleRideArray on the main thread
                DispatchQueue.main.async {
                    // If visibleRideArray doesn't have the ride (first time) then add it.
                    if self.visibleRideArray.count != self.parkRideArray.count {
                        // For first time, simply replace it with the updated internal array.
                        self.visibleRideArray = self.parkRideArray
                    } else {
                        // Otherwise, update the existing ride at the same index.
                        self.visibleRideArray[index].status = self.parkRideArray[index].status
                        self.visibleRideArray[index].waitTime = self.parkRideArray[index].waitTime
                        self.visibleRideArray[index].lastUpdated = self.parkRideArray[index].lastUpdated
                        self.visibleRideArray[index].oldStatus = self.parkRideArray[index].oldStatus
                        self.visibleRideArray[index].isFavorited = self.parkRideArray[index].isFavorited
                    }
                }
            }
        }
        
        // You might also want to call completion after all fetches finish.
        // One way to do this is to use a DispatchGroup to track when all fetchStatus calls are done.
    }
    
    
    // Apply the persisted favorite state to each ride.
//    func updateFavoriteStatus() {
//        for index in self.parkRideArray.indices {
//            self.parkRideArray[index].isFavorited = favoriteIDs.contains(self.parkRideArray[index].id)
//        }
//    }
    
    func updateRideView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Ensure visibleRideArray has the same count as parkRideArray before updating
            guard self.visibleRideArray.count == self.parkRideArray.count else {
                self.visibleRideArray = self.parkRideArray // Just replace if structure differs
                return
            }
            
            // Update only the necessary fields
            for index in self.visibleRideArray.indices {
                let newRide = self.parkRideArray[index]
                var visibleRide = self.visibleRideArray[index]
                
                visibleRide.status = newRide.status
                visibleRide.oldStatus = newRide.oldStatus
                visibleRide.waitTime = newRide.waitTime
                visibleRide.lastUpdated = newRide.lastUpdated
                
                self.visibleRideArray[index] = visibleRide // Assign back to trigger SwiftUI updates
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
        if ride.oldStatus != ride.status && ride.oldStatus != nil, let status = ride.status {
            print("Notification check for ride \(ride.name)")
            print(" --> Previous Status: \(String(describing: ride.oldStatus))")
            print(" --> Current Status: \(String(describing: ride.status))")
            notificationManager?.sendStatusChangeNotification(rideName: ride.name, newStatus: status)
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
        // timer?.invalidate() // Cancel any existing timer
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in

            AppLogger.shared.log("Timer started update")

            self?.updateRideStatus() {
            //    self?.updateFavoriteStatus()
            //    self?.updateRideView()
            }
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
        performNetworkRequest(id: entity.id) { data in
            guard let data = data else {
                completion(nil, 0, nil)
                return
            }
            // Log raw JSON response
            //            if let jsonString = String(data: data, encoding: .utf8) {
            //                print("Raw JSON Response: \(jsonString)")
            //            }
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
                }
            } catch {
                print("Error parsing status JSON: \(error)")
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
