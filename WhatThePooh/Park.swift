//
//  Park.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/13/25.
//

import SwiftUI

struct Park: Identifiable, Codable  {
    
    let id: String
    let name: String

    // This value is set via the drop-down selection. This is the last choice they chose, we persist over app launches
    var isSelected: Bool

    // We will allow the user to set this value in the preferences. This determines if it shows up in the dropdown
    var isVisible: Bool
}

struct ParkSchedule: Decodable {
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
