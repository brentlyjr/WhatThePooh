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
    
    // Toggle the favorite status of a ride
    func toggleFavorite(for ride: Ride) {
        if favoriteIDs.contains(ride.id) {
            favoriteIDs.remove(ride.id)
        } else {
            favoriteIDs.insert(ride.id)
        }
        
        // Save the updated favorites
        saveFavorites()
        
        // Update the ride's favorite status in the array
        if let index = parkRideArray.firstIndex(where: { $0.id == ride.id }) {
            parkRideArray[index].isFavorited = !ride.isFavorited
        }
        
        // Notify observers of the change
        objectWillChange.send()
    }
}
