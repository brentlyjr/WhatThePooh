//
//  SharedViewModel.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/10/25.
//

import SwiftUI

class SharedViewModel: ObservableObject {
    @Published var selectedFilter: RideFilter = .all
    @Published var sortOrder: RideSortOrder = .name
    @Published var showFavoritesOnly: Bool = false
}

enum RideFilter {
    case all
    case favorites
}

enum RideSortOrder {
    case name
    case waitTime
    case favorited
}
