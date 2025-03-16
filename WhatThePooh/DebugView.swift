//
//  DebugView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/24/25.
//

import SwiftUI

struct DebugView: View {
    @Binding var showDebugScreen: Bool

    var body: some View {
        VStack {
            HStack {
                Text("Debug Window")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                Spacer()

                Button("Close") {
                    showDebugScreen = false
                }
                .padding()
            }
            .safeAreaInset(edge: .top) { Spacer().frame(height: 50) } // Pushes content down
            Spacer()
        }
        .background(Color.blue)
        .foregroundColor(.white)
        .ignoresSafeArea()
    }
}
