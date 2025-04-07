//
//  FilterModalView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/13/25.
//

import SwiftUI

struct FilterModalView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: SharedViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            HStack {
                Text("Filter Options")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue)
            }
            .padding()
            
            // List content
            List {
                Toggle("Show Favorites Only", isOn: $viewModel.showFavoritesOnly)
                Toggle("Show Open Rides Only", isOn: $viewModel.showOpenRidesOnly)
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}
