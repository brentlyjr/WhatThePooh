//
//  ThemeParkViewModel.swift
//  ThemePark
//
//  Created by Brent Cromley on 2/2/25.
//

import Foundation
import Combine

struct ThemeParkResponse: Decodable {
    let children: [ThemeParkEntity]
}

class ThemeParkViewModel: ObservableObject {
    @Published var entities: [ThemeParkEntity] = []
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    // Retrieves all the entities (children) under a park - filters based on ATTRACTION
    // Stores them in entity array
    func fetchEntities(for destinationID: String) -> Void {
        guard let url = URL(string: "https://api.themeparks.wiki/v1/entity/\(destinationID)/children") else {
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
                let response = try decoder.decode(ThemeParkResponse.self, from: data)
                DispatchQueue.main.async {
                    self.entities = response.children.filter { $0.entityType == .attraction }
                    self.updateEntityStatuses() // Get the initial refresh of the statuses
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
            self?.updateEntityStatuses()
        }
    }

    private func updateEntityStatuses() -> Void {
        for index in entities.indices {
            let entity = entities[index]
            fetchStatus(for: entity) { [weak self] status, waitTime in
                DispatchQueue.main.async {
                    self?.entities[index].status = status
                    self?.entities[index].waitTime = waitTime
                }
            }
        }
    }

    private func fetchStatus(for entity: ThemeParkEntity, completion: @escaping (String?, Int) -> Void) -> Void {
        guard let url = URL(string: "https://api.themeparks.wiki/v1/entity/\(entity.id)/live") else {
            print("Invalid status URL")
            completion(nil, 0)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching status for \(entity.name): \(error.localizedDescription)")
                completion(nil, 0)
                return
            }

            guard let data = data else {
                print("No status data for \(entity.name)")
                completion(nil, 0)
                return
            }

            // Log raw JSON response
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Raw JSON Response: \(jsonString)")
//            }

            
            // New code to parse out waitTime, let's leave the old code here for now until I know
            // it is working well
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let liveData = jsonObject["liveData"] as? [[String: Any]], // Simplified cast directly to an array of dictionaries
                    let firstLiveData = liveData.first
                {
                    let status = firstLiveData["status"] as? String ?? "Unknown"
                    let queue = firstLiveData["queue"] as? [String: Any]
                    let standby = queue?["STANDBY"] as? [String: Any]
                    let waitTime = standby?["waitTime"] as? Int ?? 0

                    if (waitTime > 0 && status != "OPERATING") {
                        let jsonString = String(data: data, encoding: .utf8)
                        print(" Weird data field: \(jsonString ?? "NO JSON")")
                    }
//                    print("Status: \(status), waitTime: \(waitTime)")
                    completion(status, waitTime)
                }
            } catch {
                print("Failed to parse JSON: \(error.localizedDescription)")
            }
            // End test code

            
//            do {
//                let decoder = JSONDecoder()
//                let liveResponse = try decoder.decode(LiveEntityResponse.self, from: data)
//                completion(liveResponse.liveData.first?.status, 0)
//            } catch {
//                print("Error decoding status for \(entity.name): \(error)")
//                completion(nil, 0)
//            }
        }.resume()
    }
}

//struct LiveEntityResponse: Decodable {
//    let liveData: [LiveEntityData]
//}
//
//struct LiveEntityData: Decodable {
//    let status: String?
//}
