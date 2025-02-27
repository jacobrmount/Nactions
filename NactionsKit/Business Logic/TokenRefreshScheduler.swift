// BusinessLogic/TokenRefreshScheduler.swift
import Foundation
import BackgroundTasks

public final class TokenRefreshScheduler {
    static let shared = TokenRefreshScheduler()
    let taskIdentifier = "com.nactions.tokenRefresh"
    
    init() {}
    
    /// Register/initialize the background refresh mechanism
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleiOSBackgroundTask(task: task as! BGAppRefreshTask)
        }
    }
    
    /// Schedule the background task
    func scheduleTokenRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 15) // Run every 15 min
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Token refresh scheduled (iOS).")
        } catch {
            print("⚠️ Failed to schedule token refresh: \(error.localizedDescription)")
        }
    }
    
    /// Execute token refresh in the background for iOS
    func handleiOSBackgroundTask(task: BGAppRefreshTask) {
        let taskID = UUID() // For keeping track of the task
        print("⚙️ Beginning background task: \(taskID)")
        
        // Create an expiration handler
        task.expirationHandler = {
            print("⏱ Task \(taskID) expired before completion")
        }
        
        Task {
            await refreshTokensWithRetry()
            scheduleTokenRefresh() // Re-schedule next refresh
            task.setTaskCompleted(success: true)
            print("✅ Background task \(taskID) completed successfully")
        }
    }
    
    /// Shared token refresh logic with retry capability
    private func refreshTokensWithRetry() async {
        await TokenService.shared.refreshAllTokens()
        
        if await !TokenService.shared.invalidTokens.isEmpty {
            print("❌ Some tokens failed to refresh. Retrying in 5 minutes.")
            do {
                try await Task.sleep(nanoseconds: 300_000_000_000) // 5 min
                await TokenService.shared.refreshAllTokens()
            } catch {
                print("⚠️ Sleep interrupted: \(error.localizedDescription)")
            }
        }
    }
}
