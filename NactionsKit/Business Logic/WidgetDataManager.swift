// Nactions/BusinessLogic/WidgetDataManager.swift
import Foundation
import WidgetKit
import NactionsKit

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.nactions")
    
    private init() {}
    
    // MARK: - Data Sharing Methods
    
    /// Shares token data with widgets
    func shareTokensWithWidgets() {
        guard let userDefaults = userDefaults else { return }
        
        // Get tokens from TokenService (need to use await with @MainActor)
        Task { @MainActor in
            let tokens = TokenService.shared.tokens
            
            // Convert to a lightweight representation for widgets
            let widgetTokens = tokens.map { token -> [String: Any] in
                return [
                    "id": token.id.uuidString,
                    "name": token.name,
                    "isConnected": token.isConnected
                ]
            }
            
            // Store in shared user defaults
            userDefaults.set(widgetTokens, forKey: "nactions_tokens")
            
            // Refresh widgets
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    /// Shares database data with widgets
    func shareDatabaseInfo(for tokenID: UUID, databases: [NotionDatabase]) {
        guard let userDefaults = userDefaults else { return }
        
        // Convert to a lightweight representation for widgets
        let widgetDatabases = databases.map { database -> [String: Any] in
            return [
                "id": database.id,
                "title": database.title?.first?.plainText ?? "Untitled",
                "url": database.url ?? ""
            ]
        }
        
        // Store in shared user defaults
        userDefaults.set(widgetDatabases, forKey: "nactions_databases_\(tokenID.uuidString)")
    }
    
    /// Fetches databases for a token and shares them with widgets
    func refreshDatabasesForWidget(tokenID: UUID) async {
        do {
            // Find the token - wrap in MainActor for thread safety
            var token: NotionToken?
            await MainActor.run {
                token = TokenService.shared.tokens.first(where: { $0.id == tokenID })
            }
            
            guard let token = token else {
                return
            }
            
            // Create API client
            let client = NotionAPIClient(token: token.apiToken)
            
            // Create a search filter for databases
            let filter = NotionSearchFilter(property: "object", value: "database")
            
            // Search for databases
            let searchResults = try await client.searchByTitle(
                filter: filter,
                pageSize: 100
            )
            
            // Fetch full database details for each result
            var databases: [NotionDatabase] = []
            
            for result in searchResults.results where result.object == "database" {
                do {
                    let database = try await client.retrieveDatabase(databaseID: result.id)
                    databases.append(database)
                } catch {
                    print("Error fetching database \(result.id): \(error)")
                }
            }
            
            // Share with widgets
            shareDatabaseInfo(for: tokenID, databases: databases)
        } catch {
            print("Error refreshing databases: \(error)")
        }
    }
    
    // MARK: - Task List Methods
    
    /// Fetches and caches tasks for a specific database
    func fetchAndCacheTasks(tokenID: UUID, databaseID: String) async {
        do {
            // Find token - wrap in MainActor for thread safety
            var token: NotionToken?
            await MainActor.run {
                token = TokenService.shared.tokens.first(where: { $0.id == tokenID })
            }
            
            guard let token = token else {
                return
            }
            
            // Create API client
            let client = NotionAPIClient(token: token.apiToken)
            
            // Query the database for tasks
            // This assumes a specific structure for the database
            // You'll need to adapt this to your actual database schema
            let request = NotionQueryDatabaseRequest(
                sorts: [
                    NotionQuerySort(property: "Due Date", direction: "ascending")
                ],
                pageSize: 10
            )
            
            let response = try await client.queryDatabase(databaseID: databaseID, requestBody: request)
            
            // Convert response to TaskItems
            // This is a placeholder implementation
            var tasks: [TaskItem] = []
            
            for page in response.results {
                guard let pageID = page.id as? String else { continue }
                
                // Fetch the actual page to get its properties
                let notionPage = try await client.retrievePage(pageID: pageID)
                
                // Extract task data
                // This assumes specific property names - adjust as needed
                let taskTitle = extractTitleFromPage(notionPage) ?? "Untitled Task"
                let isCompleted = extractCompletionStatusFromPage(notionPage) ?? false
                let dueDate = extractDueDateFromPage(notionPage)
                
                let task = TaskItem(
                    id: pageID,
                    title: taskTitle,
                    isCompleted: isCompleted,
                    dueDate: dueDate
                )
                
                tasks.append(task)
            }
            
            // Cache the tasks for widgets
            cacheTasksForWidgets(tokenID: tokenID, databaseID: databaseID, tasks: tasks)
            
            // Refresh widgets
            WidgetCenter.shared.reloadTimelines(ofKind: "TaskListWidget")
            
        } catch {
            print("Error fetching tasks: \(error)")
        }
    }
    
    private func cacheTasksForWidgets(tokenID: UUID, databaseID: String, tasks: [TaskItem]) {
        guard let userDefaults = userDefaults else { return }
        
        // We need to convert TaskItem to a simple dictionary representation
        // since we can't store Codable objects directly in UserDefaults
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
    
    // MARK: - Progress Methods
    
    /// Fetches and caches progress data for a specific database
    func fetchAndCacheProgress(
        tokenID: UUID,
        databaseID: String,
        title: String,
        currentValueProperty: String,
        targetValueProperty: String
    ) async {
        do {
            // Find token - wrap in MainActor for thread safety
            var token: NotionToken?
            await MainActor.run {
                token = TokenService.shared.tokens.first(where: { $0.id == tokenID })
            }
            
            guard let token = token else {
                return
            }
            
            // Create API client
            let client = NotionAPIClient(token: token.apiToken)
            
            // For a real implementation, you would need to:
            // 1. Query the database
            // 2. Sum or count the relevant property values
            // This is a simplified placeholder
            
            let currentValue = try await calculatePropertyTotal(
                client: client,
                databaseID: databaseID,
                propertyName: currentValueProperty
            )
            
            let targetValue = try await calculatePropertyTotal(
                client: client,
                databaseID: databaseID,
                propertyName: targetValueProperty
            )
            
            // Create progress data
            let progress = ProgressData(
                title: title,
                currentValue: currentValue,
                targetValue: targetValue
            )
            
            // Cache for widgets
            cacheProgressForWidgets(tokenID: tokenID, databaseID: databaseID, progress: progress)
            
            // Refresh widgets
            WidgetCenter.shared.reloadTimelines(ofKind: "ProgressWidget")
            
        } catch {
            print("Error fetching progress: \(error)")
        }
    }
    
    private func cacheProgressForWidgets(tokenID: UUID, databaseID: String, progress: ProgressData) {
        guard let userDefaults = userDefaults else { return }
        
        let progressDict: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "title": progress.title,
            "currentValue": progress.currentValue,
            "targetValue": progress.targetValue,
            "percentComplete": progress.percentComplete
        ]
        
        userDefaults.set(progressDict, forKey: "nactions_progress_\(tokenID)_\(databaseID)")
    }
    
    // MARK: - Helper Methods
    
    /// Calculates a total from a property across all pages in a database
    private func calculatePropertyTotal(client: NotionAPIClient, databaseID: String, propertyName: String) async throws -> Double {
        // This is a placeholder. In a real implementation, you would:
        // 1. Query the database for all relevant pages
        // 2. Extract the specified property from each page
        // 3. Sum the values
        
        // For now, return a random value between 0 and 100
        return Double.random(in: 0...100)
    }
    
    /// Extracts the title from a Notion page
    private func extractTitleFromPage(_ page: NotionPage) -> String? {
        // This is a placeholder. In a real implementation, you would:
        // 1. Find the title property in the page.properties dictionary
        // 2. Extract the plain text value
        
        // For now, return a default title
        return "Sample Task"
    }
    
    /// Extracts the completion status from a Notion page
    private func extractCompletionStatusFromPage(_ page: NotionPage) -> Bool? {
        // This is a placeholder. In a real implementation, you would:
        // 1. Find the checkbox property in the page.properties dictionary
        // 2. Extract the boolean value
        
        // For now, return a random status
        return Bool.random()
    }
    
    /// Extracts the due date from a Notion page
    private func extractDueDateFromPage(_ page: NotionPage) -> Date? {
        // This is a placeholder. In a real implementation, you would:
        // 1. Find the date property in the page.properties dictionary
        // 2. Extract and parse the date value
        
        // For now, return a random date in the next week
        let randomOffset = Double.random(in: 0...7*24*60*60)
        return Date().addingTimeInterval(randomOffset)
    }
}

// MARK: - Extensions to NotionPage and NotionDatabase

extension NotionPage {
    /// Helper method to extract a title property value
    func titlePropertyValue(named propertyName: String) -> String? {
        guard let properties = self.properties else { return nil }
        guard let propertyValue = properties[propertyName]?.value as? [String: Any] else { return nil }
        guard let title = propertyValue["title"] as? [[String: Any]] else { return nil }
        
        // Extract text from the first title element if available
        if let firstElement = title.first,
           let text = firstElement["text"] as? [String: Any],
           let content = text["content"] as? String {
            return content
        }
        
        return nil
    }
    
    /// Helper method to extract a checkbox property value
    func checkboxPropertyValue(named propertyName: String) -> Bool? {
        guard let properties = self.properties else { return nil }
        guard let propertyValue = properties[propertyName]?.value as? [String: Any] else { return nil }
        return propertyValue["checkbox"] as? Bool
    }
    
    /// Helper method to extract a date property value
    func datePropertyValue(named propertyName: String) -> Date? {
        guard let properties = self.properties else { return nil }
        guard let propertyValue = properties[propertyName]?.value as? [String: Any] else { return nil }
        guard let dateDict = propertyValue["date"] as? [String: Any] else { return nil }
        guard let dateString = dateDict["start"] as? String else { return nil }
        
        // Parse ISO 8601 date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
    
    /// Helper method to extract a number property value
    func numberPropertyValue(named propertyName: String) -> Double? {
        guard let properties = self.properties else { return nil }
        guard let propertyValue = properties[propertyName]?.value as? [String: Any] else { return nil }
        return propertyValue["number"] as? Double
    }
}
