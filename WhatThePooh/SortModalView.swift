//
//  SortModalView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/13/25.
//

import SwiftUI

struct SortModalView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                Text("Sort by Name")
                Text("Sort by Wait Time")
                Text("Sort by Favorites")
            }
            .navigationTitle("Sort Options")
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
