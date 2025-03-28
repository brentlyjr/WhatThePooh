//
//  ContentView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var notificationManager: Notifications
    @StateObject var viewModel = SharedViewModel()
    @StateObject var parkStore = ParkStore()
    @StateObject private var rideController: RideController

    init() {
        _rideController = StateObject(wrappedValue: RideController(notificationManager: Notifications.shared))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Fixed Header
                HeaderView()
                    .environmentObject(parkStore)
                    .environmentObject(rideController)
                    .environmentObject(viewModel)

                // Scrolling RideView
                ScrollView {
                    RideView(viewModel: viewModel)
                        .environmentObject(rideController)
                        .environmentObject(parkStore)
                }
                .frame(maxWidth: .infinity)

                // Fixed Bottom Drawer
                BottomDrawerView(showSortModal: $viewModel.showSortModal, showFilterModal: $viewModel.showFilterModal)
                    .environmentObject(viewModel)
            }
            
            // Preview popup with full-screen overlay
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
                    y: 100  // Position over the header
                )
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    )
                )
                .animation(.spring(response: 1.2, dampingFraction: 0.5), value: viewModel.isPreviewVisible)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $viewModel.showSortModal) {
            SortModalView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showFilterModal) {
            FilterModalView()
        }
        .fullScreenCover(isPresented: $viewModel.showDebugWindow) {
            DebugView()
                .environmentObject(viewModel)
        }
    }
}

#Preview {
    ContentView()
}
