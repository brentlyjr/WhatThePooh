//
//  FilterModalView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/13/25.
//

import SwiftUI

struct FilterModalView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                Toggle("Show Favorites Only", isOn: .constant(false))
                Toggle("Show Open Rides Only", isOn: .constant(false))
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
