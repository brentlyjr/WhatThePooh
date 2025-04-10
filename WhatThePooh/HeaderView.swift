//
//  HeaderView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/7/25.
//

import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var viewModel: SharedViewModel
    @EnvironmentObject var notificationManager: Notifications
    @EnvironmentObject var parkStore: ParkStore
    
    // Time formatter for 12-hour format with AM/PM
    private func formatTime(_ timeString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        
        if let date = inputFormatter.date(from: timeString) {
            return outputFormatter.string(from: date)
        }
        return timeString // Return original string if parsing fails
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Park Selection Dropdown
                ParkSelectionView()
                
 //               Spacer()
                                
                // Bell Icon
                Image(systemName: parkStore.currentSelectedPark != nil && parkStore.isParkFavorited(id: parkStore.currentSelectedPark!.id) ? "bell.fill" : "bell")
                    .foregroundColor(.blue)
                    .font(.title2)
                    .onTapGesture {
                        if let park = parkStore.currentSelectedPark {
                            parkStore.toggleFavoritePark(id: park.id)
                        }
                    }

                Spacer()
                                

                // Pooh image with debug functionality
                Image("PoohImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 3)
                    .onTapGesture {
                        // Open debug window
                        viewModel.showDebugWindow = true
                        
                        // Keep existing functionality
                        Utilities.playSound()
//                        notificationManager.sendStatusChangeNotification(
//                            rideName: "Star Wars: Rise of the Resistance",
//                            newStatus: "Down",
//                            rideID: "34b1d70f-11c4-42df-935e-d5582c9f1a8e"
//                        )
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            
            // Operating Hours Display
            if let selectedPark = parkStore.currentSelectedPark,
               let todayHours = selectedPark.todayHours {
                HStack {
                    Text("Today's Hours: \(formatTime(todayHours.openingTime)) - \(formatTime(todayHours.closingTime))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 1)
            }
        }
    }
}
