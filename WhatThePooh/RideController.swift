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
