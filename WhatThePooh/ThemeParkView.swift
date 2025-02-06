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
            LazyVGrid(columns: [GridItem(.flexible(minimum: 250, maximum: .infinity)), GridItem(.flexible(minimum: 30, maximum: .infinity))], spacing: 2) {
                ForEach(viewModel.entities.indices, id: \.self) { index in
                    HStack {
                        if index % 2 == 0 {
                            Text(viewModel.entities[index].name)
                                .font(.footnote)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text(viewModel.entities[index].status ?? "Unknown") // Show status
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) // Stretch the row to fill the column
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.fetchEntities(for: "7340550b-c14d-4def-80bb-acdb51d49a66")
        }
    }
}
