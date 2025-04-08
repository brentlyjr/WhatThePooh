//
//  SettingsView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 4/7/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: SharedViewModel
    @EnvironmentObject var notificationManager: Notifications
    @EnvironmentObject var parkStore: ParkStore
    
    var body: some View {
        NavigationView {
            List {
//                Section(header: Text("Notifications")) {
//                    Toggle("Enable Notifications", isOn: .constant(notificationManager.permissionGranted))
//                        .disabled(true)
//                    
//                    if notificationManager.permissionGranted {
//                        Text("Notifications are enabled")
//                            .foregroundColor(.secondary)
//                    } else {
//                        Text("Notifications are disabled")
//                            .foregroundColor(.secondary)
//                    }
//                }
                
                Section(header: Text("Visible Parks")) {
                    ForEach(parkStore.parks) { park in
                        Toggle(park.name, isOn: Binding(
                            get: { park.isVisible },
                            set: { newValue in
                                if let index = parkStore.parks.firstIndex(where: { $0.id == park.id }) {
                                    // Update the park's visibility
                                    parkStore.parks[index].isVisible = newValue
                                    
                                    // Force a refresh of the parks array to notify SwiftUI
                                    let updatedParks = parkStore.parks
                                    parkStore.parks = updatedParks
                                    
                                    // If we're hiding the currently selected park, select the first visible park
                                    if !newValue && park.id == parkStore.currentSelectedPark?.id {
                                        if let firstVisiblePark = parkStore.parks.first(where: { $0.isVisible }) {
                                            parkStore.updateSelectedPark(to: firstVisiblePark)
                                        }
                                    }
                                }
                            }
                        ))
                        .font(.subheadline)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Created by")
                        Spacer()
                        Text("Brent Cromley, Sally Chou, Reed Cromley")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SharedViewModel())
        .environmentObject(Notifications.shared)
        .environmentObject(ParkStore())
} 
