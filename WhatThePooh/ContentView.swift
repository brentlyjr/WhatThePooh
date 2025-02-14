//
//  ContentView.swift
//  ThemePark
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        HeaderView()
            .environmentObject(Notifications.shared)
        RideView()
    }
}

#Preview {
    ContentView()
}
