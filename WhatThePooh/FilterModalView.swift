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
                // Standard toggle filters
                Section {
                    Toggle("Show Favorites Only", isOn: $viewModel.showFavoritesOnly)
                    Toggle("Show Open Rides Only", isOn: $viewModel.showOpenRidesOnly)
                }
                
                // Wait time filter section
                Section(header: Text("Wait Time Filter")) {
                    Toggle("Wait Time Less Than", isOn: $viewModel.filterByWaitTime)
                    
                    if viewModel.filterByWaitTime {
                        HStack {
                            Button(action: {
                                if viewModel.maxWaitTime > 5 {
                                    viewModel.maxWaitTime -= 5
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                            .disabled(viewModel.maxWaitTime <= 5)
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Text("\(viewModel.maxWaitTime)")
                                .font(.headline)
                                .frame(minWidth: 50)
                                .multilineTextAlignment(.center)
                            
                            Text("min")
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                if viewModel.maxWaitTime < 70 {
                                    viewModel.maxWaitTime += 5
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                            .disabled(viewModel.maxWaitTime >= 70)
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}

struct FilterModalView_Previews: PreviewProvider {
    static var previews: some View {
        FilterModalView()
            .environmentObject(SharedViewModel())
    }
}
