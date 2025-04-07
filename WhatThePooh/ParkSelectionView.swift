//
//  ParkSelectionView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/10/25.
//

import SwiftUI

struct ParkSelectionView: View {
    @EnvironmentObject var rideController: RideController
    @EnvironmentObject var parkStore: ParkStore

    var body: some View {
        // Filter parks to only show those with isVisible true
        let visibleParks = parkStore.parks.filter { $0.isVisible }
        
        // Find the currently selected park
        let selectedPark = parkStore.parks.first { $0.isSelected }

        Menu {
            ForEach(visibleParks) { park in
                Button(action: {
                    // We are going to switch the newly selected park
                    updateSelectedPark(to: park)

                    // Now fetch all the rides for that park
                    rideController.fetchRidesForPark(for: park.id) {
                        // Now upddate their statuses individually
                        rideController.updateRideStatus()
                    }
                }) {
                    Text(park.name)
                        .font(.subheadline)
                }
            }
        } label: {
            HStack(spacing: 8) {
                if let park = selectedPark {
                    Text(park.name)
                        .foregroundColor(.blue)
                        .font(.subheadline)
                } else {
                    Text("Select a Park")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
                Image(systemName: "chevron.down")
                    .foregroundColor(.blue)
                    .imageScale(.small)
            }
            .frame(maxWidth: 200)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func updateSelectedPark(to newPark: Park) {
        // Loop through all the parks. If the park is not the new one we selected, turn its isSelected
        // status to false. Unless you are the newly selected park, then turn it true!
        for index in parkStore.parks.indices {
            parkStore.parks[index].isSelected = (parkStore.parks[index].id == newPark.id)
        }
    }
}
