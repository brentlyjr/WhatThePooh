//
//  ContentView.swift
//  ThemePark
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
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
        }
        ThemeParkView()
    }
}

#Preview {
    ContentView()
}
