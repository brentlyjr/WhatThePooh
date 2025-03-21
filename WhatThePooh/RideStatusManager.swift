//
//  RideStatusManager.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/17/25.
//

import Foundation

class RideStatusManager {
    static let shared = RideStatusManager()
    private let defaults = UserDefaults.standard
    private let rideStatusKey = "rideStatusKey" // Key to store the statuses dictionary
    
    // Retrieve the stored statuses as a dictionary: [RideID: Status]
    private var lastKnownStatuses: [String: String] {
        get {
            defaults.dictionary(forKey: rideStatusKey) as? [String: String] ?? [:]
        }
        set {
            defaults.set(newValue, forKey: rideStatusKey)
        }
    }
    
    // Check a single ride's status against the stored status.
    func checkStatus(for ride: Ride) -> String? {
        // Retrieve the previously stored status.
        let previousStatus = lastKnownStatuses[ride.id]
        
        // Update the stored status with the new value, regardless of whether it changed.
        // (Or you could update only if different; here we update only if there's a difference.)
        if ride.status != previousStatus {
            lastKnownStatuses[ride.id] = ride.status
        }
        
        // Return the previous status (which could be nil)
        return previousStatus
    }
}
