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
        .edgesIgnoringSafeArea(.bottom) // Optional, depending on styling
        
        // Make the entire view tappable to dismiss the preview
        // This ensures the preview can be dismissed by tapping anywhere in the app
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.isPreviewVisible {
                viewModel.isPreviewVisible = false
            }
        }
        
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
