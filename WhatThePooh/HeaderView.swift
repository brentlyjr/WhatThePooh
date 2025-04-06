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
    
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                // Park Selection Dropdown
                ParkSelectionView()
                
                Spacer()
                
                // Heart Icon
                Image(systemName: "heart.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                // Bell Icon
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
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
                        notificationManager.sendStatusChangeNotification(
                            rideName: "Star Wars: Rise of the Resistance",
                            newStatus: "Down",
                            rideID: "34b1d70f-11c4-42df-935e-d5582c9f1a8e"
                        )
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
