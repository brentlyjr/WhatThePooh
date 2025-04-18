//
//  ParkStore.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/10/25.
//

import SwiftUI

class ParkStore: ObservableObject {
    // Singleton instance
    static let shared = ParkStore()
    
    private var isInitialLoad = true
    @Published var parks: [Park] = [] {
        didSet {
            if !isInitialLoad {
                // When parks array changes (after initial load), check for any invisible parks and remove them from favorites
                for park in parks {
                    if !park.isVisible && favoriteParkIDs.contains(park.id) {
                        favoriteParkIDs.remove(park.id)
                    }
                }
                saveFavoriteParks()
            }
            saveParks()
        }
    }
    
    @Published var currentSelectedPark: Park? {
        didSet {
            objectWillChange.send()
        }
    }
    
    private let parksKey = "parksKey"
    private let favoriteParkKey = "favoriteParks"
    private var favoriteParkIDs: Set<String> = []
    
    init() {
        print("ParkStore init()")
        loadFavoriteParks() // Load favorites first
        loadParks()        // Then load parks
        // Initialize currentSelectedPark
        currentSelectedPark = parks.first { $0.isSelected }
        // We'll set isInitialLoad to false after all async operations complete
    }
    
    private func loadParks() {
        print("Loading Parks...")
        if let data = UserDefaults.standard.data(forKey: parksKey),
           let savedParks = try? JSONDecoder().decode([Park].self, from: data) {
            self.parks = savedParks
        } else {
            // Initialize with default parks
            self.parks = [
                Park(id: "7340550b-c14d-4def-80bb-acdb51d49a66", name: "Disneyland Park", isSelected: true, isVisible: true),
                Park(id: "832fcd51-ea19-4e77-85c7-75d5843b127c", name: "Disney California Adventure Park", isSelected: false, isVisible: true),
                Park(id: "75ea578a-adc8-4116-a54d-dccb60765ef9", name: "Magic Kingdom Park", isSelected: false, isVisible: true),
                Park(id: "47f90d2c-e191-4239-a466-5892ef59a88b", name: "EPCOT", isSelected: false, isVisible: true),
                Park(id: "288747d1-8b4f-4a64-867e-ea7c9b27bad8", name: "Disney's Hollywood Studios", isSelected: false, isVisible: true),
                Park(id: "1c84a229-8862-4648-9c71-378ddd2c7693", name: "Disney's Animal Kingdom Theme Park", isSelected: false, isVisible: true),
                Park(id: "bd0eb47b-2f02-4d4d-90fa-cb3a68988e3b", name: "Hong Kong Disneyland", isSelected: false, isVisible: true),
                Park(id: "3cc919f1-d16d-43e0-8c3f-1dd269bd1a42", name: "Tokyo Disneyland", isSelected: false, isVisible: true),
                Park(id: "67b290d5-3478-4f23-b601-2f8fb71ba803", name: "Tokyo DisneySea", isSelected: false, isVisible: true),
                Park(id: "ddc4357c-c148-4b36-9888-07894fe75e83", name: "Shanghai Disneyland", isSelected: false, isVisible: true),
                Park(id: "dae968d5-630d-4719-8b06-3d107e944401", name: "Disneyland Park (Paris)", isSelected: false, isVisible: true),
                Park(id: "ca888437-ebb4-4d50-aed2-d227f7096968", name: "Walt Disney Studios Park", isSelected: false, isVisible: true)
            ]
        }
        
        // Fetch operating hours for each park
        fetchOperatingHoursForAllParks()
    }
    
    private func fetchOperatingHoursForAllParks() {
        print("Fetching park operating hours")
        let group = DispatchGroup()
        
        for park in parks {
            group.enter()
            ParkController.shared.fetchParkSchedule(for: park.id) { schedules, timezone in
                if let schedules = schedules {
                    // Update the park with the operating hours
                    park.operatingHours = schedules
                    
                    // Set the park's timezone
                    if let timezone = timezone {
                        park.timezone = timezone
                    }
                    
                    // If this is the selected park, update currentSelectedPark
                    if park.isSelected {
                        DispatchQueue.main.async {
                            self.currentSelectedPark = park
                        }
                    }
                } else {
                    print("Failed to fetch operating hours for park: \(park.name)")
                }
                group.leave()
            }
        }
        
        // When all fetch operations are complete, set isInitialLoad to false
        group.notify(queue: .main) {
            print("All park operating hours fetched, setting isInitialLoad to false")
            self.isInitialLoad = false
        }
    }
    
    private func saveParks() {
        if let encoded = try? JSONEncoder().encode(parks) {
            UserDefaults.standard.set(encoded, forKey: parksKey)
        }
    }
    
    // Function to update the selected park
    func updateSelectedPark(to newPark: Park) {
        for index in parks.indices {
            parks[index].isSelected = (parks[index].id == newPark.id)
        }
        currentSelectedPark = newPark
        saveParks() // Explicitly save to UserDefaults when selection changes
    }
    
    // MARK: - Favorite Parks Management
    
    private func loadFavoriteParks() {
        if let storedIDs = UserDefaults.standard.array(forKey: favoriteParkKey) as? [String] {
            favoriteParkIDs = Set(storedIDs)
        }
    }
    
    private func saveFavoriteParks() {
        UserDefaults.standard.set(Array(favoriteParkIDs), forKey: favoriteParkKey)
    }
    
    func toggleFavoritePark(id: String) {
        if favoriteParkIDs.contains(id) {
            favoriteParkIDs.remove(id)
        } else {
            favoriteParkIDs.insert(id)
        }
        saveFavoriteParks()
        objectWillChange.send()
    }
    
    func isParkFavorited(id: String) -> Bool {
        return favoriteParkIDs.contains(id)
    }
    
    // Clear parks from UserDefaults and reload defaults
    func clearParksAndReload() {
        print("ParkStore clearParksAndReload()")
        
        // Remove parks from UserDefaults
        UserDefaults.standard.removeObject(forKey: parksKey)
        
        // Reset isInitialLoad to true so loadParks() will use defaults
        isInitialLoad = true
        
        // Reload parks from defaults
        loadParks()
        
        // Note: We don't set isInitialLoad to false here anymore
        // It will be set to false after all async operations complete
        
        // Log the action
        AppLogger.shared.log("Cleared parks from UserDefaults and reloaded defaults")
    }
    
    // Get a park by its ID
    func getPark(withId id: String) -> Park? {
        return parks.first(where: { $0.id == id })
    }
}






//        "name": "Disneyland"
//        "id": "7340550b-c14d-4def-80bb-acdb51d49a66",

//        "name": "Disney California Adventure"
//        "id": "832fcd51-ea19-4e77-85c7-75d5843b127c",

//        "name": "Disney Magic Kingdom"
//        "id": "75ea578a-adc8-4116-a54d-dccb60765ef9",

//        "name": "EPCOT"
//        "id": "47f90d2c-e191-4239-a466-5892ef59a88b",

//        "name": "Disney's Hollywood Studios"
//        "id": "288747d1-8b4f-4a64-867e-ea7c9b27bad8",

//        "name": "Disney's Animal Kingdom"
//        "id": "1c84a229-8862-4648-9c71-378ddd2c7693",

//        "name": "Hong Kong Disneyland"
//        "id": "bd0eb47b-2f02-4d4d-90fa-cb3a68988e3b",

//        "name": "Tokyo Disneyland"
//        "id": "3cc919f1-d16d-43e0-8c3f-1dd269bd1a42",

//        "name": "Tokyo DisneySea"
//        "id": "67b290d5-3478-4f23-b601-2f8fb71ba803",

//        "name": "Shanghai Disneyland"
//        "id": "ddc4357c-c148-4b36-9888-07894fe75e83",

//        "name": "Paris Disneyland"
//        "id": "dae968d5-630d-4719-8b06-3d107e944401",

//        "name": "Paris Walt Disney Studios"
//        "id": "ca888437-ebb4-4d50-aed2-d227f7096968",





//    "name": "Walt Disney World® Resort",
//
//        "id": "75ea578a-adc8-4116-a54d-dccb60765ef9",
//        "name": "Magic Kingdom Park"
//
//        "id": "47f90d2c-e191-4239-a466-5892ef59a88b",
//        "name": "EPCOT"
//
//        "id": "288747d1-8b4f-4a64-867e-ea7c9b27bad8",
//        "name": "Disney's Hollywood Studios"
//
//        "id": "1c84a229-8862-4648-9c71-378ddd2c7693",
//        "name": "Disney's Animal Kingdom Theme Park"
//
//
//    "name": "Tokyo Disney Resort",
//
//        "id": "67b290d5-3478-4f23-b601-2f8fb71ba803",
//        "name": "Tokyo DisneySea"
//
//        "id": "3cc919f1-d16d-43e0-8c3f-1dd269bd1a42",
//        "name": "Tokyo Disneyland"
//      }
//
//
//    "name": "Disneyland Paris",
//
//        "id": "ca888437-ebb4-4d50-aed2-d227f7096968",
//        "name": "Walt Disney Studios Park"
//
//        "id": "dae968d5-630d-4719-8b06-3d107e944401",
//        "name": "Disneyland Park"
//
//
//    "name": "Shanghai Disney Resort",
//
//        "id": "ddc4357c-c148-4b36-9888-07894fe75e83",
//        "name": "Shanghai Disneyland"
//
//
//    "name": "Disneyland Resort",
//
//        "id": "7340550b-c14d-4def-80bb-acdb51d49a66",
//        "name": "Disneyland Park"
//
//        "id": "832fcd51-ea19-4e77-85c7-75d5843b127c",
//        "name": "Disney California Adventure Park"
//
//
//    "name": "Hong Kong Disneyland Parks",
//
//        "id": "bd0eb47b-2f02-4d4d-90fa-cb3a68988e3b",
//        "name": "Hong Kong Disneyland Park"
