// Nactions/BusinessLogic/AppGroupConfig.swift
import Foundation

/// Handles configuration and access to shared app group resources
struct AppGroupConfig {
    /// The shared app group identifier
    static let appGroupIdentifier = "group.com.nactions"
    
    /// Shared user defaults for the app group
    static var sharedUserDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }
    
    /// Shared container URL for the app group
    static var sharedContainerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    /// Gets the shared Core Data store URL
    static var sharedStoreURL: URL? {
        guard let containerURL = sharedContainerURL else { return nil }
        return containerURL.appendingPathComponent("NactionsDataModel.sqlite")
    }
    
    /// Checks if the app group is correctly configured
    static func verifyAppGroupAccess() -> Bool {
        guard let defaults = sharedUserDefaults else {
            print("Failed to access shared UserDefaults")
            return false
        }
        
        guard let _ = sharedContainerURL else {
            print("Failed to access shared container URL")
            return false
        }
        
        // Try writing and reading a test value
        let testKey = "appGroupAccessTest"
        let testValue = "test-\(Date().timeIntervalSince1970)"
        
        defaults.set(testValue, forKey: testKey)
        let readValue = defaults.string(forKey: testKey)
        
        let accessSuccessful = (readValue == testValue)
        if !accessSuccessful {
            print("Failed to verify app group access")
        }
        
        return accessSuccessful
    }
}

// MARK: - UserDefaults Extension for Widget Data

extension UserDefaults {
    // MARK: - Token Data
    
    /// Gets all token identifiers available for widgets
    func getTokenIDs() -> [String] {
        guard let tokens = self.array(forKey: "nactions_tokens") as? [[String: Any]] else {
            return []
        }
        
        return tokens.compactMap { $0["id"] as? String }
    }
    
    /// Gets token information suitable for widget configuration
    func getTokenInfo() -> [TokenEntity] {
        guard let tokens = self.array(forKey: "nactions_tokens") as? [[String: Any]] else {
            return []
        }
        
        return tokens.compactMap { token -> TokenEntity? in
            guard let id = token["id"] as? String,
                  let name = token["name"] as? String else {
                return nil
            }
            
            return TokenEntity(id: id, name: name)
        }
    }
    
    // MARK: - Database Data
    
    /// Gets all database IDs for a specific token
    func getDatabaseIDs(for tokenID: String) -> [String] {
        guard let databases = self.array(forKey: "nactions_databases_\(tokenID)") as? [[String: Any]] else {
            return []
        }
        
        return databases.compactMap { $0["id"] as? String }
    }
    
    /// Gets database information for a specific token
    func getDatabaseInfo(for tokenID: String) -> [String: String] {
        guard let databases = self.array(forKey: "nactions_databases_\(tokenID)") as? [[String: Any]] else {
            return [:]
        }
        
        var result: [String: String] = [:]
        
        for database in databases {
            guard let id = database["id"] as? String,
                  let title = database["title"] as? String else {
                continue
            }
            
            result[id] = title
        }
        
        return result
    }
    
    // MARK: - Task Data
    
    /// Gets cached tasks for a specific token and database
    func getCachedTasks(tokenID: String, databaseID: String) -> [TaskItem]? {
        let key = "nactions_tasks_\(tokenID)_\(databaseID)"
        
        guard let cacheData = self.dictionary(forKey: key) else {
            return nil
        }
        
        // Check if cache has expired (1 hour)
        guard let timestamp = cacheData["timestamp"] as? TimeInterval,
              Date().timeIntervalSince1970 - timestamp <= 3600 else {
            return nil
        }
        
        guard let taskDicts = cacheData["tasks"] as? [[String: Any]] else {
            return nil
        }
        
        return taskDicts.compactMap { dict -> TaskItem? in
            guard let id = dict["id"] as? String,
                  let title = dict["title"] as? String,
                  let isCompleted = dict["isCompleted"] as? Bool else {
                return nil
            }
            
            let dueDate: Date?
            if let timestamp = dict["dueDate"] as? TimeInterval {
                dueDate = Date(timeIntervalSince1970: timestamp)
            } else {
                dueDate = nil
            }
            
            return TaskItem(id: id, title: title, isCompleted: isCompleted, dueDate: dueDate)
        }
    }
    
    // MARK: - Progress Data
    
    /// Gets cached progress data for a specific token and database
    func getCachedProgress(tokenID: String, databaseID: String) -> ProgressData? {
        let key = "nactions_progress_\(tokenID)_\(databaseID)"
        
        guard let dict = self.dictionary(forKey: key),
              let timestamp = dict["timestamp"] as? TimeInterval,
              let title = dict["title"] as? String,
              let currentValue = dict["currentValue"] as? Double,
              let targetValue = dict["targetValue"] as? Double else {
            return nil
        }
        
        // Check if cache has expired (1 hour)
        guard Date().timeIntervalSince1970 - timestamp <= 3600 else {
            return nil
        }
        
        return ProgressData(title: title, currentValue: currentValue, targetValue: targetValue)
    }
}
