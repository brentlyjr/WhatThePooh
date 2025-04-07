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
        NavigationView {
            List {
                Toggle("Show Favorites Only", isOn: $viewModel.showFavoritesOnly)
                Toggle("Show Open Rides Only", isOn: $viewModel.showOpenRidesOnly)
            }
            .navigationTitle("Filter Options")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
