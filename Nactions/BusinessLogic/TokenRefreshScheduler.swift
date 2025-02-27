// BusinessLogic/TokenRefreshScheduler.swift
import Foundation
#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

#if os(macOS)
import AppKit
#endif

public final class TokenRefreshScheduler {
    static let shared = TokenRefreshScheduler()
    let taskIdentifier = "com.nactions.tokenRefresh"
    
    #if os(macOS)
    private var timer: Timer?
    #endif
    
    init() {}
    
    /// Register/initialize the background refresh mechanism
    func registerBackgroundTask() {
        #if os(iOS)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleiOSBackgroundTask(task: task as! BGAppRefreshTask)
        }
        #elseif os(macOS)
        // For macOS we'll use a combination of timer and app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        #endif
    }
    
    /// Schedule the background task
    func scheduleTokenRefresh() {
        #if os(iOS)
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 15) // Run every 15 min
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Token refresh scheduled (iOS).")
        } catch {
            print("⚠️ Failed to schedule token refresh: \(error.localizedDescription)")
        }
        #elseif os(macOS)
        // Cancel existing timer if any
        timer?.invalidate()
        
        // Schedule a timer to run every 15 minutes
        timer = Timer.scheduledTimer(
            timeInterval: 60 * 15, // 15 minutes
            target: self,
            selector: #selector(handleMacOSTimerTask),
            userInfo: nil,
            repeats: true
        )
        
        // Add the timer to the common run loop modes to keep it running during scrolling, etc.
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        print("📅 Token refresh scheduled (macOS).")
        #endif
    }
    
    #if os(iOS)
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
    #endif
    
    #if os(macOS)
    /// Handle macOS timer-based refresh
    @objc func handleMacOSTimerTask() {
        let taskID = UUID()
        print("⚙️ Beginning scheduled task: \(taskID)")
        
        Task {
            await refreshTokensWithRetry()
            print("✅ Scheduled task \(taskID) completed successfully")
        }
    }
    
    /// Handle app becoming active - good time to refresh tokens
    @objc func applicationDidBecomeActive() {
        print("📱 App became active, refreshing tokens")
        Task {
            await refreshTokensWithRetry()
        }
    }
    #endif
    
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
