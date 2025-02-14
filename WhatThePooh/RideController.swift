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
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    // Retrieves all the entities (children) under a park - filters based on ATTRACTION
    // Stores them in entity array
    func fetchEntities(for destinationID: String) -> Void {
        guard let url = URL(string: "https://api.themeparks.wiki/v1/entity/\(destinationID)/live") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received for entity/children query.")
                return
            }
            
            do {
                // Attempt to decode
                let decoder = JSONDecoder()
                let response = try decoder.decode(RideResponse.self, from: data)
                DispatchQueue.main.async {
                    self.entities = response.liveData.filter { $0.entityType == .attraction }
                    self.updateRideStatuses() // Get the initial refresh of the statuses
                    self.startStatusUpdates() // Start periodic status updates from our timer
                }
            } catch let error as DecodingError {
                switch error {
                case .typeMismatch(let type, let context):
                    print("Type mismatch: \(type), context: \(context)")
                case .valueNotFound(let type, let context):
                    print("Value not found: \(type), context: \(context)")
                case .keyNotFound(let key, let context):
                    print("Key '\(key)' not found: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                default:
                    print("Unknown decoding error: \(error)")
                }
            } catch {
                print("Other decoding error: \(error)")
            }
        }.resume()
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
    
    private func fetchStatus(for entity: RideModel, completion: @escaping (String?, Int?, String?) -> Void) -> Void {
        guard let url = URL(string: "https://api.themeparks.wiki/v1/entity/\(entity.id)/live") else {
            print("Invalid status URL")
            completion(nil, 0, nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching status for \(entity.name): \(error.localizedDescription)")
                completion(nil, 0, nil)
                return
            }
            
            guard let data = data else {
                print("No status data for \(entity.name)")
                completion(nil, 0, nil)
                return
            }
            
            // Log raw JSON response
            //            if let jsonString = String(data: data, encoding: .utf8) {
            //                print("Raw JSON Response: \(jsonString)")
            //            }
            
            
            // Parse out waitTime lastUpdated and status
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let liveData = jsonObject["liveData"] as? [[String: Any]], // Simplified cast directly to an array of dictionaries
                   let firstLiveData = liveData.first
                {
                    let status = firstLiveData["status"] as? String ?? "Unknown"
                    let queue = firstLiveData["queue"] as? [String: Any]
                    let lastUpdated = firstLiveData["lastUpdated"] as? String ?? "No Date"
                    let standby = queue?["STANDBY"] as? [String: Any]
                    let waitTime = standby?["waitTime"] as? Int
                    
                    let minutes = Utilities.minutesSince(lastUpdated)
                    print("Ride: \(entity.name), status: \(status), waitTime: \(String(describing: waitTime)), lastUpdate: \(lastUpdated), minutesSince: \(minutes ?? 0)")
                    completion(status, waitTime, lastUpdated)
                }
            } catch {
                print("Failed to parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
}
