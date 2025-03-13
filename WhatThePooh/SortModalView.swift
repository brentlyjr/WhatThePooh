//
//  SortModalView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/13/25.
//

import SwiftUI

struct SortModalView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: SharedViewModel
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    viewModel.sortOrder = .name
                }) {
                    HStack {
                        Text("Sort by Name")
                        if viewModel.sortOrder == .name {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: {
                    viewModel.sortOrder = .waitTime
                }) {
                    HStack {
                        Text("Sort by Wait Time")
                        if viewModel.sortOrder == .waitTime {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: {
                    viewModel.sortOrder = .favorited
                }) {
                    HStack {
                        Text("Sort by Favorites")
                        if viewModel.sortOrder == .favorited {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
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
