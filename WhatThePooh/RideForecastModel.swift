//
//  RideForecastModel.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 4/5/25.
//

import Foundation

struct RideForecastEntry: Identifiable {
    let id = UUID()
    let time: Date
    let waitTime: Int
    let percentage: Int
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
}

struct RideForecastData {
    let entries: [RideForecastEntry]
    
    static func parse(from json: [String: Any]) -> RideForecastData? {
        guard let liveData = json["liveData"] as? [[String: Any]],
              let firstLiveData = liveData.first,
              let forecast = firstLiveData["forecast"] as? [[String: Any]] else {
            return nil
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        
        let entries = forecast.compactMap { entry -> RideForecastEntry? in
            guard let timeString = entry["time"] as? String,
                  let time = dateFormatter.date(from: timeString),
                  let waitTime = entry["waitTime"] as? Int,
                  let percentage = entry["percentage"] as? Int else {
                return nil
            }
            
            return RideForecastEntry(time: time, waitTime: waitTime, percentage: percentage)
        }
        
        return RideForecastData(entries: entries)
    }
} 