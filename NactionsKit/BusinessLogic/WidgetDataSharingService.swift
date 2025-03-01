// NactionsKit/BusinessLogic/WidgetDataSharingService.swift
import Foundation
import WidgetKit

/// Service for sharing data between the main app and widgets
public final class WidgetDataSharingService {
    public static let shared = WidgetDataSharingService()
    
    private let userDefaults: UserDefaults?
    
    private init() {
        userDefaults = UserDefaults(suiteName: "group.com.nactions")
    }
    
    // MARK: - Widget Operations
    
    /// Refreshes all widgets
    public func refreshAllWidgets() async {
        // Share data with widgets
        shareTokenData()
        
        // Share database data for each activated token
        let tokens = TokenDataController.shared.fetchTokens().filter { $0.isActivated }
        
        for token in tokens {
            await shareDatabaseData(for: token.id)
        }
        
        // Refresh widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Data Sharing Methods
    
    /// Shares token data with widgets
    public func shareTokenData() {
        guard let userDefaults = userDefaults else { return }
        
        let tokens = TokenDataController.shared.fetchTokens()
        
        // Convert to a lightweight representation for widgets
        let widgetTokens = tokens.map { token -> [String: Any] in
            return [
                "id": token.id.uuidString,
                "name": token.name,
                "isConnected": token.isConnected,
                "isActivated": token.isActivated
            ]
        }
        
        // Store in shared UserDefaults
        userDefaults.set(widgetTokens, forKey: "nactions_tokens")
    }
    
    /// Shares database data with widgets for a specific token
    public func shareDatabaseData(for tokenID: UUID) async {
        guard let userDefaults = userDefaults else { return }
        
        do {
            // Get the token
            let tokens = TokenDataController.shared.fetchTokens()
            guard let token = tokens.first(where: { $0.id == tokenID }) else {
                return
            }
            
            // Create API client
            let client = token.createAPIClient()
            
            // Search for databases
            let filter = NotionSearchFilter()
            filter.property = "object"
            filter.value = "database"
            
            let searchResults = try await client.searchByTitle(filter: filter, pageSize: 100)
            
            // Fetch full database details
            var databases: [NotionDatabase] = []
            
            for result in searchResults.results where result.object == "database" {
                do {
                    let database = try await client.retrieveDatabase(databaseID: result.id)
                    databases.append(database)
                } catch {
                    print("Error fetching database \(result.id): \(error)")
                }
            }
            
            // Convert to a lightweight representation for widgets
            let widgetDatabases = databases.map { database -> [String: Any] in
                var dbDict: [String: Any] = [
                    "id": database.id,
                    "title": database.title?.first?.plainText ?? "Untitled",
                    "url": database.url ?? ""
                ]
                
                // Extract database schema information
                if let properties = database.properties {
                    let propertySchema = properties.mapValues { schema -> [String: Any] in
                        return [
                            "id": schema.id,
                            "name": schema.name,
                            "type": schema.type
                        ]
                    }
                    dbDict["schema"] = propertySchema
                }
                
                return dbDict
            }
            
            // Store in shared UserDefaults
            userDefaults.set(widgetDatabases, forKey: "nactions_databases_\(tokenID.uuidString)")
        } catch {
            print("Error sharing database data: \(error)")
        }
    }
    
    /// Shares task data with widgets for a specific database
    public func shareTaskData(for tokenID: UUID, databaseID: String, count: Int = 10) async {
        guard userDefaults != nil else { return }
        
        do {
            // Get the token
            let tokens = TokenDataController.shared.fetchTokens()
            guard let token = tokens.first(where: { $0.id == tokenID }) else {
                return
            }
            
            // Create API client
            let client = token.createAPIClient()
            
            // Query the database for tasks
            let request = NotionQueryDatabaseRequest(pageSize: count)
            
            let response = try await client.queryDatabase(databaseID: databaseID, requestBody: request)
            
            // Convert to task items
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
            
            // Cache the tasks
            cacheTasksForWidgets(tasks, tokenID: tokenID.uuidString, databaseID: databaseID)
            
            // Refresh task widgets
            WidgetCenter.shared.reloadTimelines(ofKind: "TaskListWidget")
        } catch {
            print("Error sharing task data: \(error)")
        }
    }
    
    /// Shares progress data with widgets
    public func shareProgressData(
        for tokenID: UUID,
        databaseID: String,
        title: String,
        currentValueProperty: String,
        targetValueProperty: String
    ) async {
        guard let userDefaults = userDefaults else { return }
        
        do {
            // Get the token
            let tokens = TokenDataController.shared.fetchTokens()
            guard let token = tokens.first(where: { $0.id == tokenID }) else {
                return
            }
            
            // Create API client
            let client = token.createAPIClient()
            
            // Query database to calculate progress
            let currentValue = try await calculatePropertyValue(client: client, databaseID: databaseID, propertyName: currentValueProperty)
            let targetValue = try await calculatePropertyValue(client: client, databaseID: databaseID, propertyName: targetValueProperty)
            
            // Create progress data
            let progress = ProgressData(
                title: title,
                currentValue: currentValue,
                targetValue: targetValue
            )
            
            // Cache for widgets
            let progressDict: [String: Any] = [
                "timestamp": Date().timeIntervalSince1970,
                "title": progress.title,
                "currentValue": progress.currentValue,
                "targetValue": progress.targetValue
            ]
            
            userDefaults.set(progressDict, forKey: "nactions_progress_\(tokenID.uuidString)_\(databaseID)")
            
            // Refresh progress widgets
            WidgetCenter.shared.reloadTimelines(ofKind: "ProgressWidget")
        } catch {
            print("Error sharing progress data: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Caches tasks for widget use
    private func cacheTasksForWidgets(
        _ tasks: [TaskItem],
        tokenID: String,
        databaseID: String
    ) {
        guard let userDefaults = userDefaults else { return }
        
        // Convert tasks to dictionaries
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
        
        // Store with timestamp
        let cacheData: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "tasks": taskDicts
        ]
        
        userDefaults.set(cacheData, forKey: "nactions_tasks_\(tokenID)_\(databaseID)")
    }
    
    /// Calculates a value from a property across all pages in a database
    private func calculatePropertyValue(
        client: NotionAPIClient,
        databaseID: String,
        propertyName: String
    ) async throws -> Double {
        // Query all database items
        let request = NotionQueryDatabaseRequest(pageSize: 100)
        let response = try await client.queryDatabase(databaseID: databaseID, requestBody: request)
        
        // Sum numeric values from the specified property
        var total: Double = 0
        
        for page in response.results {
            if let properties = page.properties,
               let prop = properties.first(where: { $0.key.lowercased() == propertyName.lowercased() }) {
                // Use extension method instead of direct casting
                if let propDict = prop.value.value.getValueDictionary(),
                   let number = propDict["number"] as? Double {
                    total += number
                }
            }
        }
        
        return total
    }
    
    /// Extracts the title from a Notion page
    private func extractTitleFromPage(_ page: NotionPage) -> String {
        if let properties = page.properties,
           let titleProp = properties.first(where: { $0.key.lowercased().contains("title") || $0.key.lowercased().contains("name") }) {
            
            // Use extension method instead of direct casting
            if let titleDict = titleProp.value.value.getValueDictionary(),
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
        
        return "Untitled"
    }
    
    /// Extracts the completion status from a Notion page
    private func extractCompletionStatusFromPage(_ page: NotionPage) -> Bool {
        if let properties = page.properties {
            // Look for common status/checkbox property names
            for propName in ["status", "complete", "done", "completed", "checkbox"] {
                if let prop = properties.first(where: { $0.key.lowercased().contains(propName) }) {
                    // Use extension method instead of direct casting
                    if let propDict = prop.value.value.getValueDictionary() {
                        // Try to extract checkbox value
                        if let checkbox = propDict["checkbox"] as? Bool {
                            return checkbox
                        }
                        
                        // Try to extract select value
                        if let select = propDict["select"] as? [String: Any],
                           let name = select["name"] as? String {
                            return ["done", "complete", "completed"].contains(name.lowercased())
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    /// Extracts the due date from a Notion page
    private func extractDueDateFromPage(_ page: NotionPage) -> Date? {
        if let properties = page.properties {
            // Look for date property
            for propName in ["date", "due", "deadline", "due date"] {
                if let prop = properties.first(where: { $0.key.lowercased().contains(propName) }) {
                    // Use extension method instead of direct casting
                    if let propDict = prop.value.value.getValueDictionary(),
                       let dateObj = propDict["date"] as? [String: Any],
                       let dateStr = dateObj["start"] as? String {
                        
                        // Parse ISO 8601 date
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        return formatter.date(from: dateStr)
                    }
                }
            }
        }
        
        return nil
    }
}
