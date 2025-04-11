//
//  AppColors.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 4/10/25.
//

import SwiftUI

struct AppColors {
    // Base colors defined with RGB values (0-255)
    private static let tealRGB = (red: 56, green: 74, blue: 81)
    private static let sandRGB = (red: 210, green: 208, blue: 186)
    private static let sageRGB = (red: 149, green: 165, blue: 166)
    private static let coralRGB = (red: 221, green: 152, blue: 142)
    private static let blueRGB = (red: 132, green: 147, blue: 174)
    private static let greyRGB = (red: 220, green: 220, blue: 220)
    private static let ochreRGB = (red: 175, green: 140, blue: 76)
    
    // Convert RGB to Color with optional opacity
    private static func color(rgb: (red: Int, green: Int, blue: Int), opacity: Double = 1.0) -> Color {
        Color(
            red: Double(rgb.red) / 255.0,
            green: Double(rgb.green) / 255.0,
            blue: Double(rgb.blue) / 255.0,
            opacity: opacity
        )
    }
    
    // Public color properties with opacity parameter
    static func sage(opacity: Double = 1.0) -> Color {
        color(rgb: sageRGB, opacity: opacity)
    }
    
    static func teal(opacity: Double = 1.0) -> Color {
        color(rgb: tealRGB, opacity: opacity)
    }
    
    static func sand(opacity: Double = 1.0) -> Color {
        color(rgb: sandRGB, opacity: opacity)
    }
    
    static func coral(opacity: Double = 1.0) -> Color {
        color(rgb: coralRGB, opacity: opacity)
    }

    static func blue(opacity: Double = 1.0) -> Color {
        color(rgb: blueRGB, opacity: opacity)
    }
    
    static func grey(opacity: Double = 1.0) -> Color {
        color(rgb: greyRGB, opacity: opacity)
    }    

    static func ochre(opacity: Double = 1.0) -> Color {
        color(rgb: ochreRGB, opacity: opacity)
    }
}
