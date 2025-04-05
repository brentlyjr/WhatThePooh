//
//  RideForecastChart.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 4/5/25.
//

import SwiftUI
import Charts

struct RideForecastChart: View {
    let forecastData: RideForecastData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Wait Time Forecast")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if forecastData.entries.isEmpty {
                Text("No forecast data available")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            } else {
                Chart {
                    ForEach(forecastData.entries) { entry in
                        LineMark(
                            x: .value("Time", entry.time),
                            y: .value("Wait Time", entry.waitTime)
                        )
                        .foregroundStyle(Color.white)
                        
                        PointMark(
                            x: .value("Time", entry.time),
                            y: .value("Wait Time", entry.waitTime)
                        )
                        .foregroundStyle(Color.white)
                    }
                    
                    // Add a vertical rule for current time
                    RuleMark(
                        x: .value("Current Time", Date())
                    )
                    .foregroundStyle(Color.yellow)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Now")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(formatTime(date))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let waitTime = value.as(Int.self) {
                                Text("\(waitTime)m")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding()
            }
        }
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
} 