//
//  Ride.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI
import Combine

struct Ride: Identifiable, Decodable {
    let id: String
    let name: String
    var status: String? // Added status property
    var waitTime: Int? // Time we are waiting
    var lastUpdated: String? // Time the last ride status was updated

    enum EntityType: String, Decodable {
        case attraction = "ATTRACTION"
        case show = "SHOW"
        case restaurant = "RESTAURANT"
        case park = "PARK"
    }
    
    let entityType: EntityType

    enum LiveStatusType: String, Decodable {
        case operating = "OPERATING"
        case down = "DOWN"
        case closed = "CLOSED"
        case refurbishment = "REFURBISHMENT"
    }
}
