//
//  WhatThePoohApp.swift
//  ThemePark
//
//  Created by Brent Cromley on 2/2/25.
//

import SwiftUI

@main
struct WhatThePoohApp: App {

    @StateObject private var notificationManager = Notifications.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear() {
                    notificationManager.requestNotificationPermissionIfNeeded()
                }
        }
    }
}
