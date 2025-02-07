//
//  ContentView.swift
//  ThemePark
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI

struct ContentView: View {
    @State private var drawerOffset: CGFloat = 300 // Start position (off-screen)
    @State private var isDrawerOpen = false // To track if drawer is open or closed
    
    var body: some View {
        HeaderView()
        ThemeParkView()
    }
}

#Preview {
    ContentView()
}
