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
    @State private var isAnimating = false
    @State private var backgroundOpacity: Double = 0.0
    
    var body: some View {
        if viewModel.isPreviewVisible, let ride = viewModel.selectedRide {
            ZStack {
                // Background overlay with controlled opacity
                Color.black
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissPopup()
                    }
                
                GeometryReader { geometry in
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
                    .frame(width: min(geometry.size.width - 40, 400))
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
                        x: geometry.size.width / 2,
                        y: (currentRideId == ride.id && forecastData != nil && !forecastData!.entries.isEmpty) ? 250 : 150
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isAnimating)
                }
            }
            .onAppear {
                // Reset forecast data when a new ride is selected
                if currentRideId != ride.id {
                    currentRideId = ride.id
                    forecastData = nil
                    fetchRideForecast(for: ride.id)
                }
                
                // Animate the background opacity first
                withAnimation(.easeIn(duration: 0.2)) {
                    backgroundOpacity = 0.3
                }
                
                // Delay the popup animation slightly to ensure proper positioning
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
                backgroundOpacity = 0.0
            }
        }
    }
    
    private func dismissPopup() {
        // Animate the popup dismissal
        withAnimation(.easeOut(duration: 0.2)) {
            isAnimating = false
            backgroundOpacity = 0.0
        }
        
        // Delay setting isPreviewVisible to false until after the animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            viewModel.isPreviewVisible = false
        }
    }
    
    private func fetchRideForecast(for rideId: String) {
        isLoadingForecast = true
        
        // Use the NetworkService to fetch the ride details
        NetworkService.shared.performNetworkRequest(id: rideId) { data in
            DispatchQueue.main.async {
                self.isLoadingForecast = false
                
                // Only update the forecast data if we're still showing the same ride
                if self.currentRideId == rideId {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let forecastData = RideForecastData.parse(from: json) {
                        self.forecastData = forecastData
                    } else {
                        print("Failed to parse ride forecast data for ride: \(rideId)")
                        self.forecastData = nil
                    }
                }
            }
        }
    }
} 
