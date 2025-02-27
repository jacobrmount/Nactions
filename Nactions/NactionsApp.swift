// Nactions/NactionsApp.swift
import SwiftUI
import BackgroundTasks

@main
struct NactionsApp: App {
    @ObservedObject var tokenService = TokenService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()  // ✅ Updated from NotionConnectionView to ContentView
                .onAppear {
                    Task {
                        await tokenService.validateStoredTokens()
                    }
                    TokenRefreshScheduler.shared.registerBackgroundTask()
                }
        }
    }
}
