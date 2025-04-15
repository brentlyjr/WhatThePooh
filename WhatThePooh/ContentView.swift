//
//  ContentView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var notificationManager: Notifications
    @EnvironmentObject var viewModel: SharedViewModel
    @EnvironmentObject var parkStore: ParkStore
    @ObservedObject private var rideController = RideController.shared
    @EnvironmentObject var parkRideManager: ParkRideManager

    init() {
        // No need to initialize rideController here anymore since we're using the singleton
    }

    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                // Fixed Header
                HeaderView()
                    .environmentObject(parkStore)
                    .environmentObject(rideController)
                    .environmentObject(viewModel)
                    .environmentObject(parkRideManager)

                // Scrolling RideView
                ScrollView {
                    RideView(viewModel: viewModel)
                        .environmentObject(rideController)
                        .environmentObject(parkStore)
                        .environmentObject(parkRideManager)
                }
                .frame(maxWidth: .infinity)

                // Fixed Bottom Drawer
                BottomDrawerView(
                    showSortModal: $viewModel.showSortModal, 
                    showFilterModal: $viewModel.showFilterModal
                )
                    .environmentObject(viewModel)
            }
            
            // Preview popup
            PreviewPopupView()
                .environmentObject(viewModel)
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $viewModel.showSortModal) {
            SortModalView()
                .environmentObject(viewModel)
                .presentationDetents([.height(280)])
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $viewModel.showFilterModal) {
            FilterModalView()
                .environmentObject(viewModel)
                .presentationDetents([.height(400)])
                .interactiveDismissDisabled(false)
        }
        .fullScreenCover(isPresented: $viewModel.showSettingsModal) {
            SettingsView()
                .environmentObject(viewModel)
                .environmentObject(notificationManager)
                .environmentObject(parkStore)
        }
        .fullScreenCover(isPresented: $viewModel.showDebugWindow) {
            DebugView()
                .environmentObject(viewModel)
        }
        .onAppear {
            setupNotificationObserver()
        }
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .openRideDetails,
            object: nil,
            queue: .main
        ) { notification in
            if let rideID = notification.userInfo?["rideID"] as? String,
               let ride = rideController.parkRideArray.first(where: { $0.id == rideID }) {
                // Update the view model to show the popup
                viewModel.selectedRide = ride
                viewModel.isPreviewVisible = true
            }
        }
    }
}

#Preview {
    ContentView()
}
