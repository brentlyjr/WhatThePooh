//
//  DebugView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/24/25.
//

import SwiftUI

struct DebugView: View {
    @EnvironmentObject var viewModel: SharedViewModel
    @EnvironmentObject var parkStore: ParkStore
    @State private var logMessages: String = ""
    @State private var favoriteRides: [String] = []
    
    var body: some View {
        VStack {
            HStack {
                Text("Debug Window")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                Spacer()

                Button("Close") {
                    viewModel.showDebugWindow = false
                }
                .padding()
            }
            .safeAreaInset(edge: .top) { Spacer().frame(height: 50) } // Pushes content down
            
            // Log Messages Section
            VStack(alignment: .leading) {
                HStack {
                    Text("Log Messages")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button("Clear Logs") {
                        AppLogger.shared.clearLogs()
                        logMessages = AppLogger.shared.getLogMessagesAsString()
                    }
                    .padding(.horizontal)
                }
                
                ScrollView {
                    Text(logMessages)
                        .font(.system(size: 10, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 400)
                .background(Color.black.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            // Add a button to clear parks and reload defaults
            Button(action: {
                parkStore.clearParksAndReload()
            }) {
                Text("Clear Parks and Reload Defaults")
                    .foregroundColor(.white)
            }
            .padding()
            
            Spacer()
        }
        .background(Color.blue)
        .foregroundColor(.white)
        .ignoresSafeArea()
        .onAppear {
            // Get messages and reverse them for display
            let messages = AppLogger.shared.getLogMessages()
            logMessages = messages.joined(separator: "\n")
            
            // Load favorite rides
            if let storedIDs = UserDefaults.standard.array(forKey: "favoriteRides") as? [String] {
                favoriteRides = storedIDs
            }
        }
    }
}
