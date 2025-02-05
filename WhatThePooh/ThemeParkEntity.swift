//
//  ThemeParkEntity.swift
//  ThemePark
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI
import Combine

struct ThemeParkEntity: Identifiable, Decodable {
    let id: String
    let name: String
    var status: String? // Added status property

    enum EntityType: String, Decodable {
        case attraction = "ATTRACTION"
        case show = "SHOW"
        case restaurant = "RESTAURANT"
    }

    let entityType: EntityType

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case entityType
    }
}
