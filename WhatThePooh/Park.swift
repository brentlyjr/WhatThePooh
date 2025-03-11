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

    // We will allow the user to set this value in the preferences. This determines if it shows up in the dropdown
    var isSelected: Bool
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
