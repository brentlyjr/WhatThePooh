//
//  MinutePickerView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 4/7/25.
//

import SwiftUI

struct MinutePickerView: View {
    @Binding var selectedMinutes: Int
    var range: ClosedRange<Int> = 0...300
    var step: Int = 5
    
    // Calculate all available values based on range and step
    private var availableValues: [Int] {
        stride(from: range.lowerBound, through: range.upperBound, by: step).map { $0 }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                Picker("Minutes", selection: $selectedMinutes) {
                    ForEach(availableValues, id: \.self) { value in
                        Text("\(value)")
                            .tag(value)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: geometry.size.width * 0.7, height: 150)
                .compositingGroup()
                .clipped()
                
                Text("min")
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
                
                Spacer()
            }
        }
        .frame(height: 150)
        .onAppear {
            // Ensure the selected value is valid within our available values
            if !availableValues.contains(selectedMinutes) {
                // Find the closest valid value
                let closest = availableValues.min(by: { abs($0 - selectedMinutes) < abs($1 - selectedMinutes) }) ?? 0
                selectedMinutes = closest
            }
        }
    }
}

// Preview provider for SwiftUI canvas
struct MinutePickerView_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(60) { selectedMinutes in
            MinutePickerView(selectedMinutes: selectedMinutes)
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}

// Helper struct for previewing views with @Binding properties
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content
    
    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: value)
        self.content = content
    }
    
    var body: some View {
        content($value)
    }
} 
