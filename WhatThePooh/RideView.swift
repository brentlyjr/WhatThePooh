//
//  ThemeParkView.swift
//  ThemePark
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI

struct RideView: View {
    @StateObject private var rideController = RideController()
    
    var body: some View {
        ScrollView {
            Grid(alignment: .leading, horizontalSpacing: 1, verticalSpacing: 5) {
                ForEach(rideController.entities.indices, id: \.self) { index in
                    let entity = rideController.entities[index] // Create a local variable for entity
                    
                    let (column2, color) = statusAttributes(status: entity.status, waitTime: entity.waitTime, lastUpdated: entity.lastUpdated)
                    
                    if (entity.status != "UNKNOWN") {
                        GridRow {
                            Text(entity.name)
                                .font(.footnote)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(column2)
                                .font(.footnote)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading) // Stretch the row to fill the column
                        .padding(1)
                        .frame(minHeight: 40, maxHeight: 40) // Add this line to set a minimum height for each GridRow
                        .background(color)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            // Load all the entities for our park
            rideController.fetchEntities(for: "faff60df-c766-4470-8adb-dee78e813f42")
            
            // Conglomeration of parks
            // Walt Disney World® Resort - e957da41-3552-4cf6-b636-5babc5cbc4e5
            // Tokyo Disney Resort - faff60df-c766-4470-8adb-dee78e813f42
            // Disneyland Paris - e8d0207f-da8a-4048-bec8-117aa946b2c2
            // Shanghai Disney Resort - 6e1464ca-1e9b-49c3-8937-c5c6f6675057
            // Disneyland Resort - bfc89fd6-314d-44b4-b89e-df1a89cf991e
            // Hong Kong Disneyland Parks - abcfffe7-01f2-4f92-ae61-5093346f5a68
            
            // Individual Parks
        }
    }
    
    private func statusAttributes(status: String?, waitTime: Int?, lastUpdated: String?) -> (String, Color) {
        
        // So for some parks, the status is not always accurate (IE, don't use REFURBISH, etc)
        // So for those odd cases, I am going to potentially change the status for display
        var calculatedStatus = status

        let minutes = Utilities.minutesSince(lastUpdated ?? Utilities.getTimeNowUTCString())
        
        // Japan, stuff can be "DOWN" for months, so if has been down for more than 2 days, let's
        // call it refurbished.
        if status == "CLOSED" && minutes! > 2880 {
            calculatedStatus = "REFURBISHMENT"
        }

        switch calculatedStatus {
        case "CLOSED":
            return ("Closed (\(minutes!) mins)", Color.blue.opacity(0.2))
        case "OPERATING":
            if let unwrappedWaitTime = waitTime {
                return ("\(unwrappedWaitTime) mins", Color.green.opacity(0.2))
            } else {
                return ("Operating (\(minutes!) mins)", Color.green.opacity(0.2))
            }
        case "DOWN":
            return ("Down (\(minutes!) mins)", Color.red.opacity(0.2))
        case "REFURBISHMENT":
            return ("Refurb (\(minutes!) mins)", Color.yellow.opacity(0.2))
        default:
            return ("Unknown (\(minutes!) mins)", Color.clear)
        }
    }
}
