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

    var body: some View {
        ScrollView {
            Grid(alignment: .leading, horizontalSpacing: 1, verticalSpacing: 5) {
                ForEach(rideController.entities.indices, id: \.self) { index in
                    let entity = rideController.entities[index] // Create a local variable for entity
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
                rideController.fetchEntities(for: selectedPark.id)
            }
        }
    }
    
    //    https://api.themeparks.wiki/v1/entity/bd0eb47b-2f02-4d4d-90fa-cb3a68988e3b/schedule - hong kong
    //    https://api.themeparks.wiki/v1/entity/bfc89fd6-314d-44b4-b89e-df1a89cf991e/schedule - disneyland

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
