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
    @Published var entities: [Ride] = []
    private var offlineMode: Bool = false
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
    // Stores them in entity array
    func fetchEntities(for destinationID: String) {
        performNetworkRequest(endpoint: destinationID) { data in
            guard let data = data else {
                print("No data received for entity query.")
                return
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(RideResponse.self, from: data)
                DispatchQueue.main.async {
                    self.entities = response.liveData.filter { $0.entityType == .attraction }
                    self.updateFavoriteStates()
                    self.updateRideStatuses()
                    self.startStatusUpdates()
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }
    }
    
    // Apply the persisted favorite state to each ride.
    private func updateFavoriteStates() {
        for index in self.entities.indices {
            self.entities[index].isFavorited = favoriteIDs.contains(self.entities[index].id)
        }
    }
    
    // Toggle the favorite state for a ride.
    func toggleFavorite(for ride: Ride) {
        guard let index = entities.firstIndex(where: { $0.id == ride.id }) else { return }
        entities[index].isFavorited.toggle()
        if entities[index].isFavorited {
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
    private func startStatusUpdates() -> Void {
        timer?.invalidate() // Cancel any existing timer
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateRideStatuses()
        }
    }
  
    // Old updateRideStatus
    private func updateRideStatuses() -> Void {
        for index in entities.indices {
            let entity = entities[index]
            DispatchQueue.main.async {
                self.fetchStatus(for: entity) { [weak self] status, waitTime, lastUpdated in
                    DispatchQueue.main.async {
                        self?.entities[index].status = status
                        self?.entities[index].waitTime = waitTime
                        self?.entities[index].lastUpdated = lastUpdated
                    }
                }
                self.sendNotificationOnStatusChange(for: entity)
            }
        }
    }

    // New updateRide statuses from ChatGPT
//    private func updateRideStatuses() -> Void {
//        for index in entities.indices {
//            let entity = entities[index]
//            
//            // Fetch the latest status for the ride
//            self.fetchStatus(for: entity) { [weak self] status, waitTime, lastUpdated in
//                guard let self = self else { return }
//                
//                // Create an updated ride (or use the fetched values directly)
//                // We send the notification regardless of app state.
//                // Note: If you want the notification to reflect the new values,
//                // you can update a temporary ride variable and pass it.
//                // For simplicity, we're still using `entity` here.
//                self.sendNotificationOnStatusChange(for: entity)
//                
//                // Only update the @Published property (thus the UI) if the app is active.
//                if UIApplication.shared.applicationState == .active {
//                    DispatchQueue.main.async {
//                        self.entities[index].status = status
//                        self.entities[index].waitTime = waitTime
//                        self.entities[index].lastUpdated = lastUpdated
//                    }
//                } else {
//                    // In background, you might still persist the latest state if needed.
//                    // For example, saving to disk or UserDefaults.
//                    // RideStatusManager.shared.saveStatuses(...)?
//                }
//            }
//        }
//    }
    
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
