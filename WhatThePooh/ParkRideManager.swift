//
//  ParkRideManager.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 4/9/25.
//

import Foundation

struct SimpleParkRide {
    let parkId: String
    let rideId: String
    let name: String
    let waitTime: Int
    let lastUpdated: Date
    let status: String?
    let prevStatus: String?  // New field to track previous status
}

class ParkRideManager {
    // Singleton instance
    static let shared = ParkRideManager()
    
    // Dictionary to store park IDs and their array of SimpleParkRide
    private var parkRideArray: [String: [SimpleParkRide]] = [:]
    
    // Flag to track if the manager has been initialized
    private var isInitialized = false
    
    // Timer for periodic updates
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 120  // 2 minutes
    
    // Private initializer to enforce singleton pattern
    private init() { }
    
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
        
        print("ParkRideManager initialized with \(parkRideArray.count) parks")
        
        // Load rides for all parks
        for parkId in parkIds {
            updateRidesForPark(for: parkId)
        }
        
        // Start the update timer
        startUpdateTimer()
    }
    
    // Start the timer for periodic updates
    private func startUpdateTimer() {
        // Cancel any existing timer
        updateTimer?.invalidate()
        
        // Create a new timer that fires every updateInterval seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
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
    private func updateAllParks() {
        print("Updating all parks...")
        for parkId in parkRideArray.keys {
            updateRidesForPark(for: parkId)
        }
    }
    
    private func updateRidesForPark(for parkId: String) {
        NetworkService.shared.performNetworkRequest(id: parkId) { [weak self] data in
            guard let self = self else { return }
            
            guard let data = data else {
                print("No data received for park \(parkId)")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let liveData = json["liveData"] as? [[String: Any]] {
                    
                    let rides = self.parseRides(from: liveData, for: parkId)
                    
                    // Copy status over from our existing ride array
                    let updatedRides = self.updateRidesWithPreviousStatus(rides, for: parkId)
                    
                    // Now update our main array
                    self.updateRides(updatedRides, for: parkId)
                    
                    let parkName = ParkStore().parks.first(where: { $0.id == parkId })?.name ?? "Unknown Park"
                    let isFavorite = ParkStore().isParkFavorited(id: parkId)
                    let parkDisplayName = isFavorite ? "\(parkName) (*)" : parkName

                    // print("Updated \(rides.count) rides for park \(parkName)")

                    // If this is a favorited park for notifications (let's see if anything changed
                    for ride in updatedRides {
                        if let prevStatus = ride.prevStatus,
                           let currentStatus = ride.status,
                           prevStatus != currentStatus {
                            print("Status changed for ride '\(ride.name)' at \(parkDisplayName): \(prevStatus) -> \(currentStatus)")
                        }
                    }
                    
                    // If this is our selected Park from the popup, let's copy this fresh data into our Ride Array
                    
                }
            } catch {
                print("Error parsing ride data for park \(parkId): \(error)")
            }
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
            
            // Extract wait time from queue->STANDBY->waitTime
            let waitTime = extractWaitTime(from: rideData)
            
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
    
    private func extractWaitTime(from rideData: [String: Any]) -> Int {
        if let queue = rideData["queue"] as? [String: Any],
           let standby = queue["STANDBY"] as? [String: Any],
           let waitTime = standby["waitTime"] as? Int {
            return waitTime
        }
        return 0
    }
    
    private func updateRides(_ rides: [SimpleParkRide], for parkId: String) {
        parkRideArray[parkId] = rides
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
