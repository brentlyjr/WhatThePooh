//
//  RideView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI

struct RideView: View {
    @ObservedObject var viewModel: SharedViewModel
    @EnvironmentObject var rideController: RideController
    @EnvironmentObject var parkStore: ParkStore
    @EnvironmentObject var notificationManager: Notifications

    var sortedRides: [Ride] {
        viewModel.sortRides(rideController.visibleRideArray)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 5) {
                ForEach(sortedRides.indices, id: \.self) { index in
                    let entity = sortedRides[index]
                    
                    // For this current entity we are processing, calculate its row color and the waittime column string
                    let (column3, color) = statusAttributes(status: entity.status, waitTime: entity.waitTime, lastUpdated: entity.lastUpdated)
                                        
                    if (entity.status != "UNKNOWN") {
                        HStack(spacing: 1) {
                            Button(action: {
                                rideController.toggleFavorite(for: entity)
                            }) {
                                Image(systemName: entity.isFavorited ? "heart.fill" : "heart")
                                    .foregroundColor(entity.isFavorited ? .red : .gray)
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
            }
            .padding()
        }
        .onAppear {
            // Load all the entities for our park. Lookup the currently selected park
            if let selectedPark = parkStore.currentSelectedPark {
                rideController.fetchRidesForPark(for: selectedPark.id) {
                    rideController.updateRideStatus()
                    // Starts a time to refresh the data in the view periodically
                    DispatchQueue.main.async {
                        rideController.startStatusUpdates()
                    }
                }
            }
        }
    }
    
    private func statusAttributes(status: String?, waitTime: Int?, lastUpdated: String?) -> (String, Color) {
        
        // So for some parks, the status is not always accurate (IE, don't use REFURBISH, etc)
        // So for those odd cases, I am going to potentially change the status for display
        let  calculatedStatus = status
        
        // let minutes = Utilities.minutesSince(lastUpdated ?? Utilities.getTimeNowUTCString())
        
        // Japan, stuff can be "DOWN" for months, so if has been down for more than 2 days, let's
        // call it refurbished.
        //        if status == "CLOSED" && minutes! > 2880 {
        //            calculatedStatus = "REFURBISHMENT"
        //        }
        
        // Once again, we are making some assumptions. If the ride is closed, but it hasn't been closed
        // for very long, then we should assume it is DOWN
        //        if status == "CLOSED" && minutes! < 240 {
        //            calculatedStatus = "DOWN"
        //        }
        
        switch calculatedStatus {
        case "CLOSED":
        //    return ("Closed (\(minutes!) mins)", Color.blue.opacity(0.2))
            return ("Closed", Color.blue.opacity(0.2))
        case "OPERATING":
            if let unwrappedWaitTime = waitTime {
                return ("\(unwrappedWaitTime) mins", Color.green.opacity(0.2))
            } else {
            //    return ("Operating (\(minutes!) mins)", Color.green.opacity(0.2))
                return ("Operating", Color.green.opacity(0.2))
            }
        case "DOWN":
        //    return ("Down (\(minutes!) mins)", Color.red.opacity(0.2))
            return ("Down", Color.red.opacity(0.2))
        case "REFURBISHMENT":
        //    return ("Refurb (\(minutes!) mins)", Color.yellow.opacity(0.2))
            return ("Refurb", Color.yellow.opacity(0.2))
        default:
            return ("Unknown", Color.clear)
        }
    }
}
