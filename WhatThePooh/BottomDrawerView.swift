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
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: { showSortModal = true }) {
                Image(systemName: "arrow.up.arrow.down")
                    .imageScale(.large)
                    .foregroundColor(.black)
            }
            Spacer()
            Button(action: { viewModel.showFavoritesOnly.toggle()}) {
                Image(systemName: "heart.fill")
                    .imageScale(.large)
                    .foregroundColor(.red)
                
            }
            Spacer()
            Button(action: { showFilterModal = true }) {
                Image(systemName: "line.horizontal.3.decrease.circle")
                    .imageScale(.large)
                    .foregroundColor(.black)
            }
            Spacer()
        }
        .frame(height: UIScreen.main.bounds.height / 15) // 1/15 of screen height
        .background(Color.gray.opacity(0.2))
        .shadow(radius: 10) // Floating effect
    }
}
