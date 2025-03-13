//
//  RideController.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/2/25.
//

import Foundation
import Combine

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
    
    init() {
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
    
    private func startStatusUpdates() -> Void {
        timer?.invalidate() // Cancel any existing timer
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateRideStatuses()
        }
    }
    
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
