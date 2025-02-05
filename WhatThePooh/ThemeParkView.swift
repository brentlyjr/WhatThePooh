//
//  ThemeParkView.swift
//  ThemePark
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI

struct ThemeParkView: View {
    @StateObject private var viewModel = ThemeParkViewModel()

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(viewModel.entities.indices, id: \.self) { index in
                    HStack {
                        if index % 2 == 0 {
                            Text(viewModel.entities[index].name)
                                .font(.footnote)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
//                                Spacer() // Placeholder for second column content
                            Text(viewModel.entities[index].status ?? "Unknown") // Show status
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("What the Pooh!")
        .onAppear {
            viewModel.fetchEntities(for: "7340550b-c14d-4def-80bb-acdb51d49a66")
        }
    }
}
