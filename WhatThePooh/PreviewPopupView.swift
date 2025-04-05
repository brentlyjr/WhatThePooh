//
//  PreviewPopupView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 4/5/25.
//

import SwiftUI

struct PreviewPopupView: View {
    @EnvironmentObject var viewModel: SharedViewModel
    @State private var forecastData: RideForecastData?
    @State private var isLoadingForecast = false
    @State private var currentRideId: String? = nil
    
    var body: some View {
        if viewModel.isPreviewVisible, let ride = viewModel.selectedRide {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.isPreviewVisible = false
                    }
                }
            
            VStack(spacing: 16) {
                // Header with ride name
                Text(ride.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                // Status information
                HStack(spacing: 24) {
                    // Status
                    VStack(spacing: 4) {
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text(ride.status ?? "Unknown")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    // Wait Time (if available)
                    if let waitTime = ride.waitTime {
                        VStack(spacing: 4) {
                            Text("Wait Time")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(waitTime) mins")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Last updated time
                if let lastUpdated = ride.lastUpdated {
                    Text("Updated: \(Utilities.minutesSince(lastUpdated) ?? 0) mins ago")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom)
                }
                
                // Forecast Chart - only show if we have data for the current ride
                if currentRideId == ride.id {
                    if isLoadingForecast {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(height: 200)
                    } else if let forecastData = forecastData, !forecastData.entries.isEmpty {
                        RideForecastChart(forecastData: forecastData)
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width - 40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.6, blue: 0.9),
                                Color(red: 0.2, green: 0.4, blue: 0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .position(
                x: UIScreen.main.bounds.width / 2,
                y: (currentRideId == ride.id && forecastData != nil && !forecastData!.entries.isEmpty) ? 250 : 150  // Position lower when showing graph
            )
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                )
            )
            .animation(.spring(response: 1.2, dampingFraction: 0.5), value: viewModel.isPreviewVisible)
            .onAppear {
                // Reset forecast data when a new ride is selected
                if currentRideId != ride.id {
                    currentRideId = ride.id
                    forecastData = nil
                    fetchRideForecast(for: ride.id)
                }
            }
        }
    }
    
    private func fetchRideForecast(for rideId: String) {
        isLoadingForecast = true
        
        // Use the RideController to fetch the ride details
        RideController.shared.performNetworkRequest(id: rideId) { data in
            DispatchQueue.main.async {
                self.isLoadingForecast = false
                
                // Only update the forecast data if we're still showing the same ride
                if self.currentRideId == rideId {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let forecastData = RideForecastData.parse(from: json) {
                        self.forecastData = forecastData
                    } else {
                        AppLogger.shared.log("Failed to parse ride forecast data for ride: \(rideId)")
                        self.forecastData = nil
                    }
                }
            }
        }
    }
} 
