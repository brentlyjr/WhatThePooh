//
//  DebugView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/24/25.
//

import SwiftUI

struct FullScreenView: View {
    @Binding var showDebugScreen: Bool

    var body: some View {
        VStack {
            Text("This is the full-screen view!")
                .padding()

            Button("Dismiss") {
                showDebugScreen = false
            }
        }
        .background(Color.blue)
        .foregroundColor(.white)
        .ignoresSafeArea()
    }
}
