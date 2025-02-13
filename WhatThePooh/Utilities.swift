//
//  Utilities.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 2/12/25.
//

import Foundation
import AVFoundation

class Utilities {
    
    static var audioPlayer: AVAudioPlayer?
    private static var poohSound: String = "pooh-laughing"
    
    // Takes a date as a string in UTC format and returns how much earlier in
    // minutes was that date from the current time. Used for determing down
    // time for rides that don't provide it
    static func minutesSince(_ utcDateString: String) -> Int? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
        
        // Convert the input string to a Date object
        guard let pastDate = dateFormatter.date(from: utcDateString) else {
            return nil // Return nil if the date string is invalid
        }
        
        // Get the current UTC time
        let currentDate = Date()
        
        // Calculate the difference in minutes
        let difference = Calendar.current.dateComponents([.minute], from: pastDate, to: currentDate)
        
        return difference.minute ?? 0
    }
    
    // Gets the exact time now in UTC format and returns it in string format
    static func getTimeNowUTCString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
        return formatter.string(from: Date())
    }
    
    static func playSound() -> Void {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error.localizedDescription)")
        }

        if let path = Bundle.main.path(forResource: poohSound, ofType: "mp3") {
            do {

                audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        } else {
            print("Cannot locate sound file: \(poohSound).")
        }
    }
}
