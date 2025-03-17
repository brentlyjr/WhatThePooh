//
//  DebugView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/24/25.
//

import SwiftUI

struct DebugView: View {
    @EnvironmentObject var viewModel: SharedViewModel

    // Function to retrieve all UserDefaults data
    func getUserDefaultsData() -> String {
        let defaults = UserDefaults.standard.dictionaryRepresentation()
        var output = "UserDefaults Data:\n\n"
        
        for (key, value) in defaults {
            output += "\(key): \(value)\n"
        }
        
        return output
    }
    
    
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
            Spacer()

            // Scrollable Text View for Displaying UserDefaults
            ScrollView {
                Text(getUserDefaultsData())
                    .font(.system(.body, design: .monospaced)) // Monospace for better readability
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.opacity(0.1))
            .cornerRadius(10)
            .padding()            
        }
        .background(Color.blue)
        .foregroundColor(.white)
        .ignoresSafeArea()
    }
}
