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
        // First, filter rides based on the showFavoritesOnly flag
        let filteredRides = viewModel.showFavoritesOnly ?
        rideController.visibleRideArray.filter { $0.isFavorited } :
        rideController.visibleRideArray
        
        switch viewModel.sortOrder {
        case .favorited:
            // Favorites come first; if both rides have the same favorited status, sort by name.
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
            // Assuming waitTime is an optional Int (Int?) in your Ride model,
            // we provide a default value (like Int.max) if waitTime is nil.
            return filteredRides.sorted {
                ($0.waitTime ?? Int.max) < ($1.waitTime ?? Int.max)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            Grid(alignment: .leading, horizontalSpacing: 1, verticalSpacing: 5) {
                ForEach(sortedRides.indices, id: \.self) { index in
                    let entity = sortedRides[index]
                    
                    // For this current entity we are processing, calculate its row color and the waittime column string
                    let (column2, color) = statusAttributes(status: entity.status, waitTime: entity.waitTime, lastUpdated: entity.lastUpdated)
                                        
                    if (entity.status != "UNKNOWN") {
                        GridRow {
                            Button(action: {
                                rideController.toggleFavorite(for: entity)
                            }) {
                                Image(systemName: entity.isFavorited ? "heart.fill" : "heart")
                                    .foregroundColor(entity.isFavorited ? .red : .gray)
                                    .imageScale(.large)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Text(entity.name)
                                .font(.footnote)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(column2)
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading) // Stretch the row to fill the column
                        .padding(1)
                        .frame(minHeight: 40, maxHeight: 40) // Add this line to set a minimum height for each GridRow
                        .background(color)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            // Load all the entities for our park. Lookup the currently selected park
            if let selectedPark = parkStore.currentSelectedPark {
                rideController.fetchRidesForPark(for: selectedPark.id) {
                    rideController.updateRideStatus() {
                        rideController.updateFavoriteStatus()
                        rideController.updateRideView()
                    }
                }
            }
        }
    }
    
    private func statusAttributes(status: String?, waitTime: Int?, lastUpdated: String?) -> (String, Color) {
        
        // So for some parks, the status is not always accurate (IE, don't use REFURBISH, etc)
        // So for those odd cases, I am going to potentially change the status for display
        var calculatedStatus = status
        
        let minutes = Utilities.minutesSince(lastUpdated ?? Utilities.getTimeNowUTCString())
        
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
            return ("Closed (\(minutes!) mins)", Color.blue.opacity(0.2))
        case "OPERATING":
            if let unwrappedWaitTime = waitTime {
                return ("\(unwrappedWaitTime) mins", Color.green.opacity(0.2))
            } else {
                return ("Operating (\(minutes!) mins)", Color.green.opacity(0.2))
            }
        case "DOWN":
            return ("Down (\(minutes!) mins)", Color.red.opacity(0.2))
        case "REFURBISHMENT":
            return ("Refurb (\(minutes!) mins)", Color.yellow.opacity(0.2))
        default:
            return ("Unknown (\(minutes!) mins)", Color.clear)
        }
    }
}
