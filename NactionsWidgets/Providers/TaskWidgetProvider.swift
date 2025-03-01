// NactionsWidgets/Providers/TaskWidgetProvider.swift
import WidgetKit
import SwiftUI
import Foundation
import NactionsKit

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
            // Fetch tasks from Notion using the shared data layer
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
            
            // Refresh every hour (or when Notion data might change)
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
            let filteredTasks = !showCompleted ? cachedTasks.filter { !$0.isCompleted } : cachedTasks
            return Array(filteredTasks.prefix(count))
        }
        
        // If we get here, we need to fetch data from Notion API
        // First, get the token
        guard let tokenUUID = UUID(uuidString: tokenID) else {
            throw WidgetError.tokenNotFound
        }
        
        // This is a simplified version - in a real app, you'd use dependency injection
        let tokenDataController = NactionsKit.TokenDataController.shared
        let token = tokenDataController.fetchToken(id: tokenUUID)
        
        // If we can't find the token, throw an error
        guard let token = token,
              let apiToken = NactionsKit.TokenDataController.shared.getSecureToken(for: tokenUUID.uuidString) else {
            throw WidgetError.tokenNotFound
        }
        
        // Create a NotionToken from the stored token
        let notionToken = NotionToken(
            id: tokenUUID,
            name: token.name ?? "Unknown",
            apiToken: apiToken
        )
        
        // Create API client
        let client = NotionAPIClient(token: notionToken.apiToken)

        // Create a query request with filters based on showCompleted parameter
        let filter = !showCompleted ? createTaskFilter() : nil
        
        let request = NotionQueryDatabaseRequest(
            filter: filter,
            pageSize: count
        )
        
        // Query the database
        let response = try await client.queryDatabase(databaseID: databaseID, requestBody: request)
        
        // Convert response to TaskItems
        var tasks: [TaskItem] = []
        
        for page in response.results {
            // Extract task data from page properties
            let taskTitle = extractTitleFromPage(page)
            let isCompleted = extractCompletionStatusFromPage(page)
            let dueDate = extractDueDateFromPage(page)
            
            let task = TaskItem(
                id: page.id,
                title: taskTitle,
                isCompleted: isCompleted,
                dueDate: dueDate
            )
            
            tasks.append(task)
        }
        
        // Cache results for future widget updates
        if let userDefaults = UserDefaults(suiteName: "group.com.nactions") {
            cacheTasksInUserDefaults(tasks, tokenID: tokenID, databaseID: databaseID, userDefaults: userDefaults)
        }
        
        return tasks
    }
    
    // Helper method to create a filter for incomplete tasks
    private func createTaskFilter() -> [String: Any] {
        // This is a simplified filter structure - you'd need to adapt it to your database schema
        return [
            "property": "Status",
            "checkbox": [
                "equals": false
            ]
        ]
    }
    
    // Helper methods to extract data from Notion pages
    private func extractTitleFromPage(_ page: NotionPage) -> String {
        if let properties = page.properties,
           let titleProp = properties.first(where: { $0.key.lowercased().contains("title") || $0.key.lowercased().contains("name") }) {
            let titleValue = titleProp.value.value
            if let titleDict = titleValue as? [String: Any],
               let titleArray = titleDict["title"] as? [[String: Any]] {
                
                // Extract text from title elements
                let texts = titleArray.compactMap { item -> String? in
                    if let textObj = item["text"] as? [String: Any],
                       let content = textObj["content"] as? String {
                        return content
                    }
                    return nil
                }
                
                return texts.joined()
            }
        }
        
        return "Untitled Task"
    }
    
    private func extractCompletionStatusFromPage(_ page: NotionPage) -> Bool {
        if let properties = page.properties {
            // Look for common status/checkbox property names
            for propName in ["status", "complete", "done", "completed", "checkbox"] {
                if let prop = properties.first(where: { $0.key.lowercased().contains(propName) }),
                   let propValue = prop.value.value as? [String: Any] {
                    
                    // Try to extract checkbox value
                    if let checkbox = propValue["checkbox"] as? Bool {
                        return checkbox
                    }
                    
                    // Try to extract select value
                    if let select = propValue["select"] as? [String: Any],
                       let name = select["name"] as? String {
                        return ["done", "complete", "completed"].contains(name.lowercased())
                    }
                }
            }
        }
        
        return false
    }
    
    private func extractDueDateFromPage(_ page: NotionPage) -> Date? {
        if let properties = page.properties {
            // Look for date property
            for propName in ["date", "due", "deadline", "due date"] {
                if let prop = properties.first(where: { $0.key.lowercased().contains(propName) }),
                   let propValue = prop.value.value as? [String: Any],
                   let dateObj = propValue["date"] as? [String: Any],
                   let dateStr = dateObj["start"] as? String {
                    
                    // Parse ISO 8601 date
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    return formatter.date(from: dateStr)
                }
            }
        }
        
        return nil
    }
    
    // Cache tasks in UserDefaults for widget access
    private func cacheTasksInUserDefaults(_ tasks: [TaskItem], tokenID: String, databaseID: String, userDefaults: UserDefaults) {
        // Convert tasks to dictionary representation for storage
        let taskDicts = tasks.map { task -> [String: Any] in
            var dict: [String: Any] = [
                "id": task.id,
                "title": task.title,
                "isCompleted": task.isCompleted
            ]
            
            if let dueDate = task.dueDate {
                dict["dueDate"] = dueDate.timeIntervalSince1970
            }
            
            return dict
        }
        
        // Store tasks with a timestamp
        let cacheData: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "tasks": taskDicts
        ]
        
        userDefaults.set(cacheData, forKey: "nactions_tasks_\(tokenID)_\(databaseID)")
    }
}
