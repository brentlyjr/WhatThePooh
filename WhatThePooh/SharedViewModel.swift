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
    @Published var rideStatusFilter: RideStatusFilter = .all
    @Published var maxWaitTime: Int = 20
    @Published var filterByWaitTime: Bool = false
    
    // Modal state of our two bottom drawer popups
    @Published var showSortModal: Bool = false
    @Published var showFilterModal: Bool = false
    @Published var showSettingsModal: Bool = false
    
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
        
        // Apply ride status filter
        switch rideStatusFilter {
        case .open:
            filteredRides = filteredRides.filter { $0.status == "OPERATING" }
        case .nonOpen:
            filteredRides = filteredRides.filter { $0.status != "OPERATING" }
        case .all:
            // No filtering needed
            break
        }
        
        // Apply wait time filter if enabled
        if filterByWaitTime {
            filteredRides = filteredRides.filter { 
                // Include rides with wait time less than or equal to maxWaitTime
                // Also include rides with no wait time (nil) as they're likely not operating
                if let waitTime = $0.waitTime {
                    return waitTime <= maxWaitTime
                }
                return true
            }
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
        case .waitTimeLowToHigh:
            // First separate rides with wait times from those without
            let ridesWithWaitTime = filteredRides.filter { $0.waitTime != nil }
            let ridesWithoutWaitTime = filteredRides.filter { $0.waitTime == nil }
            
            // Sort rides with wait times from low to high
            let sortedRidesWithWaitTime = ridesWithWaitTime.sorted { 
                ($0.waitTime ?? 0) < ($1.waitTime ?? 0) 
            }
            
            // Sort rides without wait times by name
            let sortedRidesWithoutWaitTime = ridesWithoutWaitTime.sorted { 
                $0.name < $1.name 
            }
            
            // Combine the two arrays, with rides with wait times first
            return sortedRidesWithWaitTime + sortedRidesWithoutWaitTime
        case .waitTimeHighToLow:
            // First separate rides with wait times from those without
            let ridesWithWaitTime = filteredRides.filter { $0.waitTime != nil }
            let ridesWithoutWaitTime = filteredRides.filter { $0.waitTime == nil }
            
            // Sort rides with wait times from high to low
            let sortedRidesWithWaitTime = ridesWithWaitTime.sorted { 
                ($0.waitTime ?? 0) > ($1.waitTime ?? 0) 
            }
            
            // Sort rides without wait times by name
            let sortedRidesWithoutWaitTime = ridesWithoutWaitTime.sorted { 
                $0.name < $1.name 
            }
            
            // Combine the two arrays, with rides with wait times first
            return sortedRidesWithWaitTime + sortedRidesWithoutWaitTime
        }
    }

    // New property to track splash screen visibility
    @Published var hasSeenSplash: Bool = false
}

enum RideSortOrder {
    case name
    case waitTimeLowToHigh
    case waitTimeHighToLow
    case favorited
}

enum RideStatusFilter {
    case all
    case open
    case nonOpen
}
