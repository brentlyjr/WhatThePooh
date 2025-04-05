//
//  ParkController.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/24/25.
//

import Foundation


func getTodaysOperatingHours(from jsonData: Data) -> ParkSchedule? {
    do {
        let parkData = try JSONDecoder().decode(ParkData.self, from: jsonData)
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // YYYY-MM-DD

        return parkData.schedule.first { $0.date == today && $0.type == "OPERATING" }
    } catch {
        print("Failed to decode JSON: \(error)")
        return nil
    }
}

func fetchParkSchedule(for entityId: String) {
    let urlString = "https://api.themeparks.wiki/v1/entity/\(entityId)/schedule"
    guard let url = URL(string: urlString) else {
        AppLogger.shared.log("Invalid URL for park schedule: \(urlString)")
        return
    }

    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            AppLogger.shared.log("Network error fetching park schedule: \(error.localizedDescription)")
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.shared.log("Invalid response type received")
            return
        }

        // Check HTTP status code
        guard (200...299).contains(httpResponse.statusCode) else {
            AppLogger.shared.log("HTTP error \(httpResponse.statusCode) fetching park schedule")
            return
        }

        guard let data = data else {
            AppLogger.shared.log("No data received for park schedule")
            return
        }

        if let todaySchedule = getTodaysOperatingHours(from: data) {
            AppLogger.shared.log("Today's hours: \(todaySchedule.openingTime) - \(todaySchedule.closingTime)")
        } else {
            AppLogger.shared.log("No operating hours found for today")
        }
    }.resume()
}

// Usage example:
// fetchParkSchedule(for: "67b290d5-3478-4f23-b601-2f8fb71ba803")
