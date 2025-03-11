//
//  ContentView.swift
//  ThemePark
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI

struct ContentView: View {

    @StateObject var viewModel = SharedViewModel()
    
    var body: some View {
        HeaderView(viewModel: viewModel)
            .environmentObject(Notifications.shared)
        RideView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}
