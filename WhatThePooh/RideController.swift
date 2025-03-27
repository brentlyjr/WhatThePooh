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
    
    private let notificationManager: Notifications
    
    init(notificationManager: Notifications) {
        self.notificationManager = notificationManager
        loadFavorites()
    }
    
    // Retrieves all the entities (children) under a park - filters based on ATTRACTION
    // Stores them in a rideArray
    func fetchRidesForPark(for destinationID: String, completion: @escaping () -> Void) {
        performNetworkRequest(endpoint: destinationID) { data in
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
    func updateRideStatus(completion: @escaping () -> Void) {
        
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
                
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .global()) {
            completion()
        }
    }

    // Apply the persisted favorite state to each ride.
    func updateFavoriteStatus() {
        for index in self.parkRideArray.indices {
            self.parkRideArray[index].isFavorited = favoriteIDs.contains(self.parkRideArray[index].id)
        }
    }
    
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
        print("Notification check for ride \(ride.name)")

        // Now let's see if the status has changed for our entity, we also find out if this entity didn't have a value yet
//        let (statusChanged, emptyValue ) = RideStatusManager.shared.checkStatus(for: ride)
//        
//        // Our ride status changed, but this is a boostrap case, so we don't send notification this time
//        if statusChanged && emptyValue {
//            print("First time getting status for ride \(ride.name)")
//            print(" --> Current Status: \(String(describing: ride.status))")
//        }
//
//        print(" --> Current Status: \(String(describing: ride.status))")
//        print(" --> Previous Status: \(String(describing: ride.previousStatus))")
//
//        // Our ride status changed, and the value was not empty (IE, we had a previous stored state
//        if statusChanged && !emptyValue, let status = ride.status {
//            notificationManager.sendStatusChangeNotification(rideName: ride.name, newStatus: status)
//        }

        // Else, our status hasn't changed so don't do anything
    }

//    // This is the function that checks a ride's status and sends a notification if has changed
//    private func sendNotificationOnStatusChange(for ride: Ride) {
//        print("Notification check for ride \(ride.name)")
//        
//        // Get the previously stored status and update the stored value with the new one.
//        let previousStatus = RideStatusManager.shared.checkStatus(for: ride)
//        
//        // Define if this is the first time getting a status.
//        let isFirstTime = (previousStatus == nil || previousStatus?.isEmpty == true)
//        
//        // Determine if the status has changed (i.e. new status differs from what was stored)
//        let statusChanged = (ride.status != previousStatus)
//        
//        print(" --> Current Status: \(String(describing: ride.status))")
//        print(" --> Previous Status: \(String(describing: previousStatus))")
//        
//        if statusChanged {
//            if isFirstTime {
//                // This is the bootstrap case: first time receiving a status, so don't notify.
//                print("First time getting status for ride \(ride.name)")
//            } else if let status = ride.status {
//                // Send notification if the status has changed and we have a valid current status.
//                notificationManager.sendStatusChangeNotification(rideName: ride.name, newStatus: status)
//            }
//        }
//
//        // Else, our status hasn't changed so don't do anything
//    }
    
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

            print("Fetching new ride statuses...")

            self?.updateRideStatus() {
                self?.updateFavoriteStatus()
                self?.updateRideView()
            }
        }
    }
    
    private func fetchStatus(for entity: Ride, completion: @escaping (String?, Int?, String?) -> Void) {
        performNetworkRequest(endpoint: entity.id) { data in
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
    
    private func performNetworkRequest(endpoint: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: "https://api.themeparks.wiki/v1/entity/\(endpoint)/live") else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(data)
        }.resume()
    }
}
