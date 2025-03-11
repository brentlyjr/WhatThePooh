//
//  ContentView.swift
//  ThemePark
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI

struct ContentView: View {

    @StateObject var viewModel = SharedViewModel()
    @StateObject private var rideController = RideController()

    var body: some View {
        HeaderView(viewModel: viewModel)
            .environmentObject(Notifications.shared)
            .environmentObject(rideController)
        RideView(viewModel: viewModel)
            .environmentObject(rideController)
    }
}

#Preview {
    ContentView()
}
