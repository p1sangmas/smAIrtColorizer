//
//  ImageColorizerApp.swift
//  ImageColorizer
//
//  Created by Fakhrul Fauzi on 20/03/2025.
//

import SwiftUI

@main
struct ImageColorizerApp: App {
    // Use scene phase for managing app lifecycle
    @Environment(\.scenePhase) private var scenePhase
    
    // Create a shared history manager that will be available throughout the app
    @StateObject private var historyManager = HistoryManager()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.light)
                .environmentObject(historyManager) // Make the history manager available to all views
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Handle app lifecycle events if needed
            switch newPhase {
            case .active:
                print("App is active")
                historyManager.loadHistory() // Reload history when app becomes active
            case .inactive:
                print("App is inactive")
            case .background:
                print("App is in background")
            @unknown default:
                print("Unknown scene phase")
            }
        }
    }
}
