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

    func fetchEntities(for destinationID: String) {
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
                print("No data received")
                return
            }

            // Log raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response: \(jsonString)")
            }

            do {
                // Attempt to decode
                let decoder = JSONDecoder()
                let response = try decoder.decode(ThemeParkResponse.self, from: data)
                DispatchQueue.main.async {
                    self.entities = response.children.filter { $0.entityType == .attraction }
                    self.startStatusUpdates() // Start periodic status updates
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
                print("Other error: \(error)")
            }
        }.resume()
    }

    private func startStatusUpdates() {
        timer?.invalidate() // Cancel any existing timer
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.updateEntityStatuses()
        }
    }

    private func updateEntityStatuses() {
        for index in entities.indices {
            let entity = entities[index]
            fetchStatus(for: entity) { [weak self] status in
                DispatchQueue.main.async {
                    self?.entities[index].status = status
                }
            }
        }
    }

    private func fetchStatus(for entity: ThemeParkEntity, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.themeparks.wiki/v1/entity/\(entity.id)/live") else {
            print("Invalid status URL")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching status for \(entity.name): \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No status data for \(entity.name)")
                completion(nil)
                return
            }

            do {
                let decoder = JSONDecoder()
                let liveResponse = try decoder.decode(LiveEntityResponse.self, from: data)
                completion(liveResponse.liveData.first?.status)
            } catch {
                print("Error decoding status for \(entity.name): \(error)")
                completion(nil)
            }
        }.resume()
    }
}

struct LiveEntityResponse: Decodable {
    let liveData: [LiveEntityData]
}

struct LiveEntityData: Decodable {
    let status: String?
}
