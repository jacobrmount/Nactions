// Nactions/NactionsApp.swift
import SwiftUI
import NactionsKit

@main
struct NactionsApp: App {
    // Initialize Core Data stack
    let coreDataStack = CoreDataStack.shared
    
    init() {
        // Set up any necessary Core Data transformers
        setupValueTransformers()
        
        // Configure app for widget sharing
        AppGroupConfig.configureAppForWidgetSharing()
        
        // Register for background refresh
        setupBackgroundTasks()
        
        // Initialize Core Data stack and verify model
        let coreDataStack = CoreDataStack.shared
        coreDataStack.verifyModelAccess()
        
        // Verify app group access
        let groupAccessSuccessful = AppGroupConfig.verifyAppGroupAccess()
        if !groupAccessSuccessful {
            print("⚠️ Failed to access app group - widgets may not work correctly")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .onAppear {
                    refreshDataOnLaunch()
                }
        }
    }
    
    private func setupBackgroundTasks() {
        TokenRefreshScheduler.shared.registerBackgroundTask()
        TokenRefreshScheduler.shared.scheduleTokenRefresh()
    }
    
    private func setupValueTransformers() {
        // Register Core Data transformers
        RichTextTransformer.register()
        NotionPropertiesTransformer.register()
    }
    
    private func refreshDataOnLaunch() {
        // Refresh tokens when app launches
        Task {
            await TokenService.shared.refreshAllTokens()
            
            // Share data with widgets
            await AppGroupConfig.refreshWidgetData()
            
            // Clean up old cache data
            AppGroupConfig.cleanupCacheData()
        }
    }
}
