//
//  ParkController.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/24/25.
//

import Foundation

class ParkController {
    // Singleton instance
    static let shared = ParkController()
    
    private init() {}
    
    func fetchParkSchedule(for entityId: String, completion: @escaping ([ParkSchedule]?, String?) -> Void) {
        let urlString = "https://api.themeparks.wiki/v1/entity/\(entityId)/schedule"
        guard let url = URL(string: urlString) else {
            print("\(ISO8601DateFormatter().string(from: Date())) - Invalid URL: \(urlString)")
            completion(nil, nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("\(ISO8601DateFormatter().string(from: Date())) - Network error: \(error.localizedDescription)")
                completion(nil, nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("\(ISO8601DateFormatter().string(from: Date())) - Invalid response type")
                completion(nil, nil)
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("\(ISO8601DateFormatter().string(from: Date())) - HTTP error: \(httpResponse.statusCode)")
                completion(nil, nil)
                return
            }
            
            guard let data = data else {
                print("\(ISO8601DateFormatter().string(from: Date())) - No data received")
                completion(nil, nil)
                return
            }
            
            do {
                let parkData = try JSONDecoder().decode(ParkData.self, from: data)
                completion(parkData.schedule, parkData.timezone)
            } catch {
                print("\(ISO8601DateFormatter().string(from: Date())) - Decoding error: \(error)")
                completion(nil, nil)
            }
        }
        
        task.resume()
    }
}
