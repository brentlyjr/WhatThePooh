//
//  BottomDrawer.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/13/25.
//

import SwiftUI

struct BottomDrawerView: View {
    @Binding var showSortModal: Bool
    @Binding var showFilterModal: Bool
    @EnvironmentObject var viewModel: SharedViewModel
    
    private var isAnyFilterActive: Bool {
        viewModel.showFavoritesOnly || 
        viewModel.rideStatusFilter != .all || 
        viewModel.filterByWaitTime
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top separator line
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5)
            
            // Button row
            HStack(spacing: 0) {
                Spacer()
                
                // Sort button
                Button(action: { showSortModal = true }) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.teal())
                }
                .buttonStyle(BottomDrawerButtonStyle())
                .help("Sort Rides")
                
                Spacer()
                
                // Favorites button
                Button(action: { viewModel.showFavoritesOnly.toggle() }) {
                    Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.teal())
                }
                .buttonStyle(BottomDrawerButtonStyle())
                .help("Show Favorites Only")
                
                Spacer()
                
                // Filter button
                Button(action: { showFilterModal = true }) {
                    Image(systemName: isAnyFilterActive ? "line.horizontal.3.decrease.circle.fill" : "line.horizontal.3.decrease.circle")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.teal())
                }
                .buttonStyle(BottomDrawerButtonStyle())
                .help("Filter Rides")
                
                Spacer()
                
                // Settings button
                Button(action: { viewModel.showSettingsModal = true }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.teal())
                }
                .buttonStyle(BottomDrawerButtonStyle())
                .help("Settings")
                
                Spacer()
            }
            .frame(height: 50)
            .padding(.vertical, 0)
            .padding(.bottom, 16)
            .background(AppColors.sand())
        }
        .background(AppColors.sand())
        .clipShape(
            RoundedCorner(radius: 16, corners: [.topLeft, .topRight])
        )
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: -2)
    }
}

// Custom button style for bottom drawer buttons
struct BottomDrawerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                Circle()
                    .fill(Color.black.opacity(configuration.isPressed ? 0.1 : 0))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Helper shape for top rounded corners only
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
