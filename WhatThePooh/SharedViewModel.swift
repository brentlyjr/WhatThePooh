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

    // This is something we will load from our Info.plist. When we are running a debug
    // versino of our app, this will be set to true and we will have access to a debug
    // window that will display internal stats
    @Published var showDebugWindow: Bool = false
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
