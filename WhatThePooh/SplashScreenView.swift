//
//  SplashScreenView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 4/8/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var titleOffset: CGFloat = 100
    @State private var titleOpacity: Double = 0
    
    var body: some View {
        // Main container that fills the screen
        ZStack {
            // Background that fills the entire screen
            Color.blue
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    // White border
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(Color.white, lineWidth: 20)
                        .edgesIgnoringSafeArea(.all)
                )
            
            // Content
            VStack(spacing: 20) {
                // App Icon
                Image("PoohImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .background(
                        Circle()
                            .fill(.white)
                            .frame(width: 140, height: 140)
                    )
                    .opacity(1)
                
                // App Title
                Text("What The Pooh!")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .offset(x: 0)
                    .opacity(titleOpacity)
            }
        }
        .onAppear {
            // Play sound using existing Utilities class
            Utilities.playSound()
                        
            // Animate title slide in and fade in
            withAnimation(.easeIn(duration: 1.0)) {
                titleOpacity = 1
            }
        }
    }
} 
