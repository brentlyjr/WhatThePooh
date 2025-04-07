//
//  SharedViewModel.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/10/25.
//

import SwiftUI

class SharedViewModel: ObservableObject {
    // Filter and sort states for our RideView
    @Published var sortOrder: RideSortOrder = .name
    @Published var showFavoritesOnly: Bool = false
    @Published var showOpenRidesOnly: Bool = false
    
    // Modal state of our two bottom drawer popups
    @Published var showSortModal: Bool = false
    @Published var showFilterModal: Bool = false
    
    // State for managing the ride preview popup
    // selectedRide: The currently selected ride to show in the preview
    // isPreviewVisible: Controls whether the preview is currently shown
    @Published var selectedRide: Ride?
    @Published var isPreviewVisible: Bool = false

    // This is something we will load from our Info.plist. When we are running a debug
    // version of our app, this will be set to true and we will have access to a debug
    // window that will display internal stats
    @Published var showDebugWindow: Bool = false
    
    // Helper function to sort rides based on current sort order
    func sortRides(_ rides: [Ride]) -> [Ride] {
        // First, apply filters
        var filteredRides = rides
        
        // Apply favorites filter if enabled
        if showFavoritesOnly {
            filteredRides = filteredRides.filter { $0.isFavorited }
        }
        
        // Apply open rides filter if enabled
        if showOpenRidesOnly {
            filteredRides = filteredRides.filter { $0.status == "OPERATING" }
        }
        
        // Then apply sorting
        switch sortOrder {
        case .favorited:
            // Favorites come first; if both rides have the same favorited status, sort by name
            return filteredRides.sorted {
                if $0.isFavorited != $1.isFavorited {
                    return $0.isFavorited && !$1.isFavorited
                } else {
                    return $0.name < $1.name
                }
            }
        case .name:
            return filteredRides.sorted { $0.name < $1.name }
        case .waitTime:
            return filteredRides.sorted {
                ($0.waitTime ?? Int.max) < ($1.waitTime ?? Int.max)
            }
        }
    }
}

enum RideSortOrder {
    case name
    case waitTime
    case favorited
}
