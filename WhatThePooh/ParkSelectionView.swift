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
        let selectedPark = parkStore.currentSelectedPark

        Menu {
            ForEach(visibleParks) { park in
                Button(action: {
                    // Update the selected park
                    parkStore.updateSelectedPark(to: park)

                    // Now fetch all the rides for that park
                    rideController.fetchRidesForPark(for: park.id)
                }) {
                    Text(park.name)
                        .font(.subheadline)
                }
            }
        } label: {
            HStack(spacing: 8) {
                if let park = selectedPark {
                    Text(park.name)
                        .foregroundColor(AppColors.teal())
                        .font(.subheadline)
                } else {
                    Text("Select a Park")
                        .foregroundColor(AppColors.teal())
                        .font(.subheadline)
                }
                Image(systemName: "chevron.down")
                    .foregroundColor(AppColors.teal())
                    .imageScale(.small)
            }
            .frame(maxWidth: 400)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.sand())
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
