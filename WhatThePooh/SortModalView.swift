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
        VStack(spacing: 0) {
            // Custom header
            HStack {
                Text("Sort Options")
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
                    viewModel.sortOrder = .waitTimeLowToHigh
                }) {
                    HStack {
                        Text("Sort by Wait Time (Low to High)")
                        if viewModel.sortOrder == .waitTimeLowToHigh {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: {
                    viewModel.sortOrder = .waitTimeHighToLow
                }) {
                    HStack {
                        Text("Sort by Wait Time (High to Low)")
                        if viewModel.sortOrder == .waitTimeHighToLow {
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
            .listStyle(InsetGroupedListStyle())
        }
    }
}
