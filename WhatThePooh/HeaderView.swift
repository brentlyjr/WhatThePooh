//
//  HeaderView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/7/25.
//

import SwiftUI

struct HeaderView: View {
    @State private var selectedOption = "Disney Land"
    let options = ["Disney Land", "Disney World", "Disney Paris"]

    var body: some View {
        VStack {
            HStack {
                Text("What The Pooh!")
                    .fontWeight(.bold)
                    .font(.largeTitle)
                Image("PoohImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 7)
                    .onTapGesture {
                        Utilities.playSound()
                    }
            }
            
//            HStack {
//                Text("Park: \(selectedOption)")
//                
//                Picker("Select a Park", selection: $selectedOption) {
//                    ForEach(options, id: \.self) { option in
//                        Text(option).tag(option)
//                    }
//                }
//                .pickerStyle(MenuPickerStyle()) // Dropdown-style appearance
//            }
//            .padding()
        }
    }
}
