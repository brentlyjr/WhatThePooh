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
    var isFavorited: Bool = false // Has the user favorited this ride, will be read from user preferences
    
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

    enum CodingKeys: String, CodingKey {
        case id, name, isFavorited, status, waitTime, lastUpdated, entityType
    }
    
    // Override the default decoder so we can handle an optional value that does not come from the API
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // These three values come from the entity API query from api.themeparks.wiki
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        entityType = try container.decode(EntityType.self, forKey: .entityType)

        // These values we will fill in later, they don't come from a different API query
        status = nil
        waitTime = nil
        lastUpdated = nil

        // isFavorited does not come from API, so just use default value of "false" for now
        // This setting will be loaded from user preferences
        isFavorited = false
    }
}
