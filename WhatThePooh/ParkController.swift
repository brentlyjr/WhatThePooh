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
    
    func fetchParkSchedule(for entityId: String, completion: @escaping ([ParkSchedule]?) -> Void) {
        let urlString = "https://api.themeparks.wiki/v1/entity/\(entityId)/schedule"
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                completion(nil)
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("HTTP error: \(httpResponse.statusCode)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            do {
                let parkData = try JSONDecoder().decode(ParkData.self, from: data)
                print("Successfully decoded schedule with \(parkData.schedule.count) entries")
                completion(parkData.schedule)
            } catch {
                print("Decoding error: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
}
