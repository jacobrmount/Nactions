// BusinessLogic/TokenRefreshScheduler.swift
import BackgroundTasks

public final class TokenRefreshScheduler {
    static let shared = TokenRefreshScheduler()
    let taskIdentifier = "com.nactions.tokenRefresh"

    init() {}

    /// Register the background task
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
    }

    /// Schedule the background task
    func scheduleTokenRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 15) // Run every 15 min

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Token refresh scheduled.")
        } catch {
            print("⚠️ Failed to schedule token refresh: \(error.localizedDescription)")
        }
    }

    /// Execute token refresh in the background
    func handleBackgroundTask(task: BGAppRefreshTask) {
        Task {
            await TokenService.shared.refreshAllTokens()
            
            if await !TokenService.shared.invalidTokens.isEmpty {
                print("❌ Some tokens failed to refresh. Retrying in 5 minutes.")
                Task {
                    try await Task.sleep(nanoseconds: 300_000_000_000) // 5 min
                    await TokenService.shared.refreshAllTokens()
                }
            }

            scheduleTokenRefresh() // Re-schedule next refresh
            task.setTaskCompleted(success: true)
        }
    }
}
