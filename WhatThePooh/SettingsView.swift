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
    @EnvironmentObject var parkStore: ParkStore
    @State private var selectedTab = 0
    
    struct CompactToggleStyle: ToggleStyle {
        var isDisabled: Bool = false
        
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.label
                    .font(.subheadline)
                    .foregroundColor(isDisabled ? .gray : .primary)
                Spacer()
                Button(action: {
                    if !isDisabled {
                        configuration.isOn.toggle()
                    }
                }) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(configuration.isOn ? (isDisabled ? Color.gray : Color.blue) : Color.gray.opacity(0.4))
                        .frame(width: 40, height: 24)
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .shadow(radius: 1)
                                .frame(width: 20, height: 20)
                                .offset(x: configuration.isOn ? 8 : -8)
                                .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isDisabled)
            }
            .padding(.vertical, 1)
        }
    }
    
    // MARK: - Extracted Views
    
    private var tabPicker: some View {
        Picker("Settings", selection: $selectedTab) {
            Text("Parks").tag(0)
            Text("Colors").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    private var parksTab: some View {
        List {
            Section(header: Text("Visible Parks")) {
                ForEach(parkStore.parks) { park in
                    parkToggle(for: park)
                }
            }
        }
        .tag(0)
    }
    
    private func parkToggle(for park: Park) -> some View {
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
        .toggleStyle(CompactToggleStyle(isDisabled: park.id == parkStore.currentSelectedPark?.id))
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .overlay(
            Group {
                if park.id == parkStore.currentSelectedPark?.id {
                    Text("Currently Selected")
                        .font(.caption)
                        .foregroundColor(.black)
                        .padding(.trailing, 8)
                }
            },
            alignment: .trailing
        )
    }
    
    private var colorsTab: some View {
        List {
            statusColorsSection
            aboutSection
        }
        .tag(1)
    }
    
    private var statusColorsSection: some View {
        Section(header: Text("Status Colors")) {
            ColorPicker("Open", selection: $viewModel.openColor)
                .onChange(of: viewModel.openColor) { oldValue, newValue in
                    viewModel.saveStatusColors()
                }
            
            ColorPicker("Down", selection: $viewModel.downColor)
                .onChange(of: viewModel.downColor) { oldValue, newValue in
                    viewModel.saveStatusColors()
                }
            
            ColorPicker("Refurbishment", selection: $viewModel.refurbColor)
                .onChange(of: viewModel.refurbColor) { oldValue, newValue in
                    viewModel.saveStatusColors()
                }
            
            ColorPicker("Closed", selection: $viewModel.closedColor)
                .onChange(of: viewModel.closedColor) { oldValue, newValue in
                    viewModel.saveStatusColors()
                }
            
            Button("Reset to Defaults") {
                viewModel.resetStatusColors()
            }
            .foregroundColor(.red)
        }
    }
    
    private var aboutSection: some View {
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
    
    private var debugSection: some View {
        Section(header: Text("Debug")) {
            Toggle("Show Debug Window", isOn: $viewModel.showDebugWindow)
        }
    }
    
    private var tabView: some View {
        TabView(selection: $selectedTab) {
            parksTab
            colorsTab
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
    
    private var navigationBarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
                dismiss()
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                tabPicker
                tabView
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                navigationBarItems
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
