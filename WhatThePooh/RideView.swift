//
//  RideView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI

// Extracted RideRow component
struct RideRow: View {
    let entity: Ride
    @ObservedObject var viewModel: SharedViewModel
    @EnvironmentObject var rideController: RideController
    @EnvironmentObject var parkStore: ParkStore
    
    var body: some View {
        let (column3, color) = statusAttributes(status: entity.status, waitTime: entity.waitTime, lastUpdated: entity.lastUpdated)
        
        if (entity.status != "UNKNOWN") {
            HStack(spacing: 1) {
                Button(action: {
                    rideController.toggleFavorite(for: entity)
                }) {
                    Image(systemName: entity.isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(AppColors.teal())
                        .imageScale(.large)
                }
                .buttonStyle(BorderlessButtonStyle())
                .frame(maxWidth: 40)
                
                Text(entity.name)
                    .font(.footnote)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(column3)
                    .font(.footnote)
                    .frame(width: 80)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(1)
            .frame(minHeight: 40, maxHeight: 40)
            .background(color)
            .cornerRadius(8)
            .onTapGesture {
                withAnimation(.spring(response: 1.2, dampingFraction: 0.5)) {
                    viewModel.selectedRide = entity
                    viewModel.isPreviewVisible = true
                }
            }
        }
    }
    
    private func statusAttributes(status: String?, waitTime: Int?, lastUpdated: String?) -> (String, Color) {
        // So for some parks, the status is not always accurate (IE, don't use REFURBISH, etc)
        // So for those odd cases, I am going to potentially change the status for display
        var calculatedStatus = status

        // TODO: i have noticed the first time through this the status appears to be 'nil'.
        // Why is that, it should never be nil unless something went wrong.
                
        // TODO: Is there a better way to do this then to call "isParkOpen()" everytime
        // I am worried that is re-parsing the string every time, which doesn't seem efficient
        
        // Check park open/closed status
        if let selectedPark = parkStore.currentSelectedPark {

            // If the Park isn't open, but the ride status says "OPEN", let's mark is CLOSED.
            // Shanghai and some parks do this incorrectly. They leave the ride open even
            // after the park has closed.
            if (!selectedPark.isOpen && status == "OPERATING") {
                calculatedStatus = "CLOSED"
            }
        }

        // let minutes = Utilities.minutesSince(lastUpdated ?? Utilities.getTimeNowUTCString())
        
        // Japan, stuff can be "DOWN" for months, so if has been down for more than 2 days, let's
        // call it refurbished.
        //        if status == "CLOSED" && minutes! > 2880 {
        //            calculatedStatus = "REFURBISHMENT"
        //        }
        
        // Now that we have our calculated status, let's return the appropriate color and text
        switch calculatedStatus {
        case "OPERATING":
            if let unwrappedWaitTime = waitTime {
                return ("\(unwrappedWaitTime) mins", viewModel.openColor)
            } else {
                return ("Open", viewModel.openColor)
            }
        case "DOWN":
            return ("Down", viewModel.downColor)
        case "REFURBISHMENT":
            return ("Refurb", viewModel.refurbColor)
        case "CLOSED":
            return ("Closed", viewModel.closedColor)
        default:
            return ("Unknown", Color.gray)
        }
    }
}

struct RideView: View {
    @ObservedObject var viewModel: SharedViewModel
    @EnvironmentObject var rideController: RideController
    @EnvironmentObject var parkStore: ParkStore
    @EnvironmentObject var parkRideManager: ParkRideManager

    var sortedRides: [Ride] {
        viewModel.sortRides(rideController.parkRideArray)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 5) {
                ForEach(sortedRides) { entity in
                    RideRow(entity: entity, viewModel: viewModel)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onAppear {
            // Load all the entities for our park. Lookup the currently selected park
            if let selectedPark = parkStore.currentSelectedPark {
                // rideController.fetchRidesForPark(for: selectedPark.id)
                parkRideManager.updateRidesForPark(for: selectedPark.id)
            }
        }
    }
}
