// NactionsWidgets/Providers/WidgetProviders.swift
import WidgetKit
import SwiftUI
import Foundation
import NactionsKit

// MARK: - Task Widget Provider
struct TaskWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = TaskEntry
    typealias Intent = TaskWidgetConfigurationIntent
    
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(
            date: Date(),
            configuration: TaskWidgetConfigurationIntent(),
            tasks: NactionsKit.TaskItem.samples,
            error: nil
        )
    }
    
    func snapshot(for configuration: TaskWidgetConfigurationIntent, in context: Context) async -> TaskEntry {
        // Return sample data for the widget gallery
        TaskEntry(
            date: Date(),
            configuration: configuration,
            tasks: NactionsKit.TaskItem.samples,
            error: nil
        )
    }
    
    func timeline(for configuration: TaskWidgetConfigurationIntent, in context: Context) async -> Timeline<TaskEntry> {
        var entries: [TaskEntry] = []
        let currentDate = Date()
        
        // Check if we have the required configuration
        guard let tokenID = configuration.tokenID, !tokenID.isEmpty,
              let databaseID = configuration.databaseID, !databaseID.isEmpty else {
            let entry = TaskEntry(
                date: currentDate,
                configuration: configuration,
                tasks: [],
                error: "Please configure the widget with a valid Notion token and database."
            )
            return Timeline(entries: [entry], policy: .never)
        }
        
        do {
            // Fetch tasks from Notion using your existing API client
            let tasks = try await fetchTasks(
                tokenID: tokenID,
                databaseID: databaseID,
                count: configuration.taskCount,
                showCompleted: configuration.showCompleted
            )
            
            // Create an entry with the fetched tasks
            let entry = TaskEntry(
                date: currentDate,
                configuration: configuration,
                tasks: tasks,
                error: nil
            )
            entries.append(entry)
            
            // Refresh every hour or when Notion data might change
            let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
            
            return Timeline(entries: entries, policy: .after(nextUpdateDate))
        } catch {
            let entry = TaskEntry(
                date: currentDate,
                configuration: configuration,
                tasks: [],
                error: "Failed to fetch tasks: \(error.localizedDescription)"
            )
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
        }
    }
    
    // MARK: - API Methods
    
    private func fetchTasks(tokenID: String, databaseID: String, count: Int, showCompleted: Bool) async throws -> [NactionsKit.TaskItem] {
        // Try to get from shared UserDefaults cache first
        if let userDefaults = UserDefaults(suiteName: "group.com.nactions"),
           let cachedTasks = userDefaults.getCachedTasks(tokenID: tokenID, databaseID: databaseID) {
            // Filter by completion status if needed
            if !showCompleted {
                return cachedTasks.filter { !$0.isCompleted }
            } else {
                return cachedTasks
            }
        }
        
        // No valid cache, return sample data for now
        // In a real implementation, you would call your API client here
        return NactionsKit.TaskItem.samples
    }
    
    // Helper method to create a filter based on configuration
    private func createTaskFilter(showCompleted: Bool) -> [String: Any]? {
        // Simple filter structure
        if !showCompleted {
            return [
                "property": "Status",
                "checkbox": [
                    "equals": false
                ]
            ]
        }
        return nil
    }
}

// MARK: - Progress Widget Provider
struct ProgressWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = ProgressEntry
    typealias Intent = ProgressWidgetConfigurationIntent
    
    func placeholder(in context: Context) -> ProgressEntry {
        ProgressEntry(
            date: Date(),
            configuration: ProgressWidgetConfigurationIntent(),
            progress: NactionsKit.ProgressData.sample,
            error: nil
        )
    }
    
    func snapshot(for configuration: ProgressWidgetConfigurationIntent, in context: Context) async -> ProgressEntry {
        // Return sample data for the widget gallery
        ProgressEntry(
            date: Date(),
            configuration: configuration,
            progress: NactionsKit.ProgressData.sample,
            error: nil
        )
    }
    
    func timeline(for configuration: ProgressWidgetConfigurationIntent, in context: Context) async -> Timeline<ProgressEntry> {
        var entries: [ProgressEntry] = []
        let currentDate = Date()
        
        // Check if we have the required configuration
        guard let tokenID = configuration.tokenID, !tokenID.isEmpty,
              let databaseID = configuration.databaseID, !databaseID.isEmpty,
              let currentValueProperty = configuration.currentValueProperty, !currentValueProperty.isEmpty,
              let targetValueProperty = configuration.targetValueProperty, !targetValueProperty.isEmpty else {
            let entry = ProgressEntry(
                date: currentDate,
                configuration: configuration,
                progress: NactionsKit.ProgressData(title: configuration.title, currentValue: 0, targetValue: 0),
                error: "Please configure the widget with valid Notion settings."
            )
            return Timeline(entries: [entry], policy: .never)
        }
        
        do {
            // Fetch progress data from Notion using your existing API client
            let progressData = try await fetchProgressData(
                tokenID: tokenID,
                databaseID: databaseID,
                title: configuration.title,
                currentValueProperty: currentValueProperty,
                targetValueProperty: targetValueProperty
            )
            
            // Create an entry with the fetched progress data
            let entry = ProgressEntry(
                date: currentDate,
                configuration: configuration,
                progress: progressData,
                error: nil
            )
            entries.append(entry)
            
            // Refresh every hour or when Notion data might change
            let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
            
            return Timeline(entries: entries, policy: .after(nextUpdateDate))
        } catch {
            let entry = ProgressEntry(
                date: currentDate,
                configuration: configuration,
                progress: NactionsKit.ProgressData(title: configuration.title, currentValue: 0, targetValue: 0),
                error: "Failed to fetch progress data: \(error.localizedDescription)"
            )
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
        }
    }
    
    // MARK: - API Methods
    
    private func fetchProgressData(
        tokenID: String,
        databaseID: String,
        title: String,
        currentValueProperty: String,
        targetValueProperty: String
    ) async throws -> NactionsKit.ProgressData {
        // Try to get from shared UserDefaults cache first
        if let userDefaults = UserDefaults(suiteName: "group.com.nactions"),
           let cachedProgress = userDefaults.getCachedProgress(tokenID: tokenID, databaseID: databaseID) {
            return cachedProgress
        }
        
        // No valid cache, return sample data for now
        // In a real implementation, you would call your API client here
        return NactionsKit.ProgressData.sample
    }
}
