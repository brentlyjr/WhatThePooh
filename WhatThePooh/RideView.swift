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
        ZStack {
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
                                viewModel.selectedRide = entity
                                viewModel.isPreviewVisible = true
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Preview popup with full-screen overlay
            if viewModel.isPreviewVisible, let ride = viewModel.selectedRide {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.isPreviewVisible = false
                    }
                
                VStack {
                    Text(ride.name)
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                }
                .frame(width: 200)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 10, x: 0, y: 5)
                .position(
                    x: UIScreen.main.bounds.width / 2,
                    y: UIScreen.main.bounds.height / 2
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isPreviewVisible)
            }
        }
        .contentShape(Rectangle())
        .onAppear {
            // Load all the entities for our park. Lookup the currently selected park
            if let selectedPark = parkStore.currentSelectedPark {
                rideController.fetchRidesForPark(for: selectedPark.id) {
                    rideController.updateRideStatus() {
                    //    rideController.updateFavoriteStatus()
                    //    rideController.updateRideView()
                        // Starts a time to refresh the data in the view periodically
                        DispatchQueue.main.async {
                            rideController.startStatusUpdates()
                        }
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
            return ("Unknown (\(minutes!) mins)", Color.clear)
        }
    }
}
