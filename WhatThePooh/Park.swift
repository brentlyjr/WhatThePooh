//
//  Park.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/13/25.
//

import SwiftUI

class Park: Identifiable, Codable  {
    
    let id: String
    let name: String

    // This value is set via the drop-down selection. This is the last choice they chose, we persist over app launches
    var isSelected: Bool

    // We will allow the user to set this value in the preferences. This determines if it shows up in the dropdown
    var isVisible: Bool
    
    // Operating hours for the park
    var operatingHours: [ParkSchedule] = []
    
    // Computed property to get today's operating hours
    var todayHours: ParkSchedule? {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // YYYY-MM-DD
        return operatingHours.first { $0.date == today && $0.type == "OPERATING" }
    }
    
    // Initializer
    init(id: String, name: String, isSelected: Bool, isVisible: Bool) {
        self.id = id
        self.name = name
        self.isSelected = isSelected
        self.isVisible = isVisible
        self.operatingHours = []
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isSelected
        case isVisible
        case operatingHours
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isSelected = try container.decode(Bool.self, forKey: .isSelected)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        operatingHours = try container.decodeIfPresent([ParkSchedule].self, forKey: .operatingHours) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isSelected, forKey: .isSelected)
        try container.encode(isVisible, forKey: .isVisible)
        try container.encode(operatingHours, forKey: .operatingHours)
    }
}

struct ParkSchedule: Codable {
    let date: String
    let type: String
    let openingTime: String
    let closingTime: String
}

struct ParkData: Decodable {
    let id: String
    let name: String
    let timezone: String
    let schedule: [ParkSchedule]
}
