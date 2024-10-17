//
//  VestaSleep_CompanionApp.swift
//  VestaSleep Companion Watch App
//
//  Created by Alejandro Enríquez on 16/10/24.
//

import SwiftUI
import WatchConnectivity

@main
struct VestaSleep_Companion_Watch_AppApp: App {
    @StateObject private var healthKitManager = HealthKitManager()

        init() {
            setupWatchConnectivity()
        }

        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(healthKitManager)
            }
        }

        private func setupWatchConnectivity() {	
            if WCSession.isSupported() {
                WCSession.default.delegate = healthKitManager
                WCSession.default.activate()
            }
        }
}
