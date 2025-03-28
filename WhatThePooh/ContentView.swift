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

    @State private var showSortModal = false
    @State private var showFilterModal = false

    init(notificationManager: Notifications) {
        _rideController = StateObject(wrappedValue: RideController(notificationManager: notificationManager))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Fixed Header
            HeaderView()
                .environmentObject(Notifications.shared)
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
            BottomDrawer(showSortModal: $showSortModal, showFilterModal: $showFilterModal)
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
        
        .sheet(isPresented: $showSortModal) {
            SortModalView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showFilterModal) {
            FilterModalView()
        }
        .fullScreenCover(isPresented: $viewModel.showDebugWindow) {
            DebugView()
                .environmentObject(viewModel)
        }
    }
}

#Preview {
    ContentView(notificationManager: Notifications.shared)
}
