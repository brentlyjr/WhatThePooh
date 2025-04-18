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
    
    // Notification settings
    @Published var chattyNotifications: Bool = false
    
    // Status colors for ride statuses
    @Published var openColor: Color = AppColors.sage(opacity: 1.0)
    @Published var downColor: Color = AppColors.coral(opacity: 1.0)
    @Published var refurbColor: Color = AppColors.sand(opacity: 1.0)
    @Published var closedColor: Color = Color.clear
    
    // UserDefaults keys for status colors
    private let openColorKey = "openColor"
    private let downColorKey = "downColor"
    private let refurbColorKey = "refurbColor"
    private let closedColorKey = "closedColor"
    
    // UserDefaults key for sort order
    private let sortOrderKey = "sortOrder"
    
    // UserDefaults key for chatty notifications
    private let chattyNotificationsKey = "chattyNotifications"
    
    init() {
        // Load saved colors from UserDefaults
        loadStatusColors()
        
        // Load saved sort order from UserDefaults
        loadSortOrder()
        
        // Load saved notification settings
        loadNotificationSettings()
    }
    
    // Load notification settings from UserDefaults
    private func loadNotificationSettings() {
        chattyNotifications = UserDefaults.standard.bool(forKey: chattyNotificationsKey)
    }
    
    // Save notification settings to UserDefaults
    func saveNotificationSettings() {
        UserDefaults.standard.set(chattyNotifications, forKey: chattyNotificationsKey)
    }
    
    // Load sort order from UserDefaults
    private func loadSortOrder() {
        if let savedSortOrderString = UserDefaults.standard.string(forKey: sortOrderKey) {
            switch savedSortOrderString {
            case "name":
                sortOrder = .name
            case "waitTimeLowToHigh":
                sortOrder = .waitTimeLowToHigh
            case "waitTimeHighToLow":
                sortOrder = .waitTimeHighToLow
            case "favorited":
                sortOrder = .favorited
            default:
                sortOrder = .name // Default if the saved value is invalid
            }
        }
    }
    
    // Save sort order to UserDefaults
    func saveSortOrder() {
        var sortOrderString: String
        switch sortOrder {
        case .name:
            sortOrderString = "name"
        case .waitTimeLowToHigh:
            sortOrderString = "waitTimeLowToHigh"
        case .waitTimeHighToLow:
            sortOrderString = "waitTimeHighToLow"
        case .favorited:
            sortOrderString = "favorited"
        }
        
        UserDefaults.standard.set(sortOrderString, forKey: sortOrderKey)
    }
    
    // Load status colors from UserDefaults
    private func loadStatusColors() {
        if let openColorData = UserDefaults.standard.data(forKey: openColorKey),
           let downColorData = UserDefaults.standard.data(forKey: downColorKey),
           let refurbColorData = UserDefaults.standard.data(forKey: refurbColorKey),
           let closedColorData = UserDefaults.standard.data(forKey: closedColorKey) {
            
            if let openColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: openColorData) {
                self.openColor = Color(openColor)
            }
            
            if let downColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: downColorData) {
                self.downColor = Color(downColor)
            }
            
            if let refurbColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: refurbColorData) {
                self.refurbColor = Color(refurbColor)
            }
            
            if let closedColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: closedColorData) {
                self.closedColor = Color(closedColor)
            }
        }
    }
    
    // Save status colors to UserDefaults
    func saveStatusColors() {
        if let openColorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(openColor), requiringSecureCoding: false) {
            UserDefaults.standard.set(openColorData, forKey: openColorKey)
        }
        
        if let downColorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(downColor), requiringSecureCoding: false) {
            UserDefaults.standard.set(downColorData, forKey: downColorKey)
        }
        
        if let refurbColorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(refurbColor), requiringSecureCoding: false) {
            UserDefaults.standard.set(refurbColorData, forKey: refurbColorKey)
        }
        
        if let closedColorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(closedColor), requiringSecureCoding: false) {
            UserDefaults.standard.set(closedColorData, forKey: closedColorKey)
        }
    }
    
    // Reset status colors to defaults
    func resetStatusColors() {
        openColor = AppColors.sage(opacity: 0.5)
        downColor = AppColors.coral(opacity: 0.5)
        refurbColor = AppColors.sand(opacity: 0.5)
        closedColor = Color.clear
        saveStatusColors()
    }
    
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
            
            // Sort rides without wait times by status and then by name
            let sortedRidesWithoutWaitTime = ridesWithoutWaitTime.sorted { 
                // First sort by status priority: OPERATING > CLOSED > REFURBISHMENT
                let statusPriority1 = getStatusPriority($0.status)
                let statusPriority2 = getStatusPriority($1.status)
                
                if statusPriority1 != statusPriority2 {
                    return statusPriority1 < statusPriority2
                } else {
                    // If status is the same, sort by name
                    return $0.name < $1.name
                }
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
            
            // Sort rides without wait times by status and then by name
            let sortedRidesWithoutWaitTime = ridesWithoutWaitTime.sorted { 
                // First sort by status priority: OPERATING > CLOSED > REFURBISHMENT
                let statusPriority1 = getStatusPriority($0.status)
                let statusPriority2 = getStatusPriority($1.status)
                
                if statusPriority1 != statusPriority2 {
                    return statusPriority1 < statusPriority2
                } else {
                    // If status is the same, sort by name
                    return $0.name < $1.name
                }
            }
            
            // Combine the two arrays, with rides with wait times first
            return sortedRidesWithWaitTime + sortedRidesWithoutWaitTime
        }
    }
    
    // Helper function to get priority for status sorting
    private func getStatusPriority(_ status: String?) -> Int {
        guard let status = status else { return 999 } // Unknown status gets lowest priority
        
        switch status {
        case "OPERATING":
            return 0 // Highest priority
        case "DOWN":
            return 1
        case "CLOSED":
            return 2
        case "REFURBISHMENT":
            return 3
        default:
            return 999 // Unknown status gets lowest priority
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
