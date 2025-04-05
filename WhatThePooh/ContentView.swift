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
    @StateObject private var rideController = RideController.shared

    init() {
        // No need to initialize rideController here anymore since we're using the singleton
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
            
            // Preview popup
            PreviewPopupView()
                .environmentObject(viewModel)
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
