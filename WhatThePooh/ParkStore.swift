//
//  ParkStore.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/10/25.
//

import SwiftUI

class ParkStore: ObservableObject {
    @Published var parks: [Park] = [] {
        didSet {
            saveParks()
        }
    }
    
    @Published var currentSelectedPark: Park? {
        didSet {
            objectWillChange.send()
        }
    }
    
    private let parksKey = "parksKey"
    
    init() {
        loadParks()
        // Initialize currentSelectedPark
        currentSelectedPark = parks.first { $0.isSelected }
    }
    
    private func loadParks() {
        if let data = UserDefaults.standard.data(forKey: parksKey),
           let savedParks = try? JSONDecoder().decode([Park].self, from: data) {
            self.parks = savedParks
        } else {
            // Initialize with default parks (assume the first 5 are selected)
            self.parks = [
                Park(id: "7340550b-c14d-4def-80bb-acdb51d49a66", name: "Disneyland", isSelected: true, isVisible: true),
                Park(id: "832fcd51-ea19-4e77-85c7-75d5843b127c", name: "California Adventure", isSelected: false, isVisible: true),
                Park(id: "75ea578a-adc8-4116-a54d-dccb60765ef9", name: "Magic Kingdom", isSelected: false, isVisible: true),
                Park(id: "47f90d2c-e191-4239-a466-5892ef59a88b", name: "EPCOT", isSelected: false, isVisible: true),
                Park(id: "288747d1-8b4f-4a64-867e-ea7c9b27bad8", name: "Hollywood Studios", isSelected: false, isVisible: true),
                Park(id: "1c84a229-8862-4648-9c71-378ddd2c7693", name: "Animal Kingdom", isSelected: false, isVisible: true),
                Park(id: "bd0eb47b-2f02-4d4d-90fa-cb3a68988e3b", name: "Hong Kong Disneyland", isSelected: false, isVisible: true),
                Park(id: "3cc919f1-d16d-43e0-8c3f-1dd269bd1a42", name: "Tokyo Disneyland", isSelected: false, isVisible: false),
                Park(id: "67b290d5-3478-4f23-b601-2f8fb71ba803", name: "Tokyo Disney Sea", isSelected: false, isVisible: false),
                Park(id: "ddc4357c-c148-4b36-9888-07894fe75e83", name: "Shanghai Disneyland", isSelected: false, isVisible: false),
                Park(id: "dae968d5-630d-4719-8b06-3d107e944401", name: "Paris Disneyland", isSelected: false, isVisible: false),
                Park(id: "ca888437-ebb4-4d50-aed2-d227f7096968", name: "Paris Walt Disney Studios", isSelected: false, isVisible: false)
            ]
        }
        
        // Fetch operating hours for each park
        fetchOperatingHoursForAllParks()
    }
    
    private func fetchOperatingHoursForAllParks() {
        for park in parks {
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
            }
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
