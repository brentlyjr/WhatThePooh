//
//  AppLogger.swift
//  WhatThePooh
//
//  Created by Brent Cromley on 3/17/25.
//

import Foundation

class AppLogger {
    static let shared = AppLogger()
    private let defaults = UserDefaults.standard
    private let logKey = "appLogMessages"
    private let maxLogEntries = 1000 // Maximum number of log entries to keep
    
    private var logMessages: [String] {
        get {
            defaults.stringArray(forKey: logKey) ?? []
        }
        set {
            defaults.set(newValue, forKey: logKey)
        }
    }
    
    private init() {}
    
    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] \(message)"
        
        // Add new message to the end of the array
        logMessages.append(logEntry)
        
        // Trim array if it exceeds maxLogEntries
        if logMessages.count > maxLogEntries {
            logMessages = Array(logMessages.suffix(maxLogEntries))
        }
    }
    
    func getLogMessages() -> [String] {
        return logMessages
    }
    
    func clearLogs() {
        logMessages = []
    }
    
    func getLogMessagesAsString() -> String {
        return logMessages.joined(separator: "\n")
    }
} 