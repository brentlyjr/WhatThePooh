//
//  SplashScreenView.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 4/8/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var titleOpacity: Double = 0
    
    var body: some View {
        // Main container that fills the screen
        ZStack {
            
            // Background that fills the entire screen
            Color.blue
                .edgesIgnoringSafeArea(.all)
            
            // Content
            VStack(spacing: 20) {
                
                Spacer()
                // App Title
                Text("What The Pooh!")
                    .font(.custom("Chalkboard SE", size: 40))
                    .bold()
                    .foregroundColor(.white)
                    .opacity(titleOpacity)
                    .frame(maxWidth: .infinity, alignment: .center)
                
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
                Spacer()
                Spacer()

            }
        }
        .onAppear {
            // Play Pooh sound using existing Utilities class
            Utilities.playSound()
            
            // Animate title slide in and fade in
            withAnimation(.easeIn(duration: 1.0)) {
                titleOpacity = 1
            }
        }
    }
}
