//
//  ThemeParkViewModel.swift
//  ThemePark
//
//  Created by Brent Cromley on 2/2/25.
//

import Foundation
import Combine

struct RideResponse: Decodable {
    let liveData: [RideModel]
}

class RideController: ObservableObject {
    @Published var entities: [RideModel] = []
    private var offlineMode: Bool = false
    private var timer: Timer?
    
    init() {
        // Set offlineMode during initialization
        self.offlineMode = isOfflineModeEnabled()
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
                    self.updateRideStatuses()
                    self.startStatusUpdates()
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }
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
    
    private func fetchStatus(for entity: RideModel, completion: @escaping (String?, Int?, String?) -> Void) {
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
        if self.offlineMode {
            loadMockData(endpoint: endpoint, completion: completion)
        } else {
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
    
    private func isOfflineModeEnabled() -> Bool {
        let key = "OFFLINE_MODE"
        if let offlineMode = Bundle.main.object(forInfoDictionaryKey: key) as? Bool {
            print("Found \(key): \(offlineMode)")
            return offlineMode
        } else {
            print("\(key) key not found. Defaulting to false.")
            return false
        }
    }
    
    private func loadMockData(endpoint: String, completion: @escaping (Data?) -> Void) {
        if let path = Bundle.main.path(forResource: "DisneyJapan-02-13-2025-OPEN", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                completion(data)
            } catch {
                print("Failed to load mock data: \(error)")
                completion(nil)
            }
        } else {
            print("Mock JSON file not found for \(endpoint)")
            completion(nil)
        }
    }
}
