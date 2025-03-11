//
//  ParkSelectionView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/10/25.
//

import SwiftUI

struct ParkSelectionView: View {
    @StateObject var parkStore = ParkStore()
    @State private var selectedPark: Park? = nil
    @EnvironmentObject var rideController: RideController
    
    var body: some View {
        // Filter parks to include only those that are selected
        let selectedParks = parkStore.parks.filter { $0.isSelected }
        
        Menu {
            // Create a button for each selected park
            ForEach(selectedParks) { park in
                Button(action: {
                    selectedPark = park
                    // Call the fetch method with the selected park's id
                    rideController.fetchEntities(for: park.id)
                }) {
                    Text(park.name)
                }
            }
        } label: {
            HStack {
                if let park = selectedPark {
                    Text(park.name)
                } else {
                    Text("Select a Park")
                }
                Image(systemName: "chevron.down")
            }
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .padding()
    }
}
