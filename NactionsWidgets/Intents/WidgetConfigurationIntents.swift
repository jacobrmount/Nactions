// NactionsWidgets/Intents/WidgetConfigurationIntents.swift
import WidgetKit
import AppIntents
import SwiftUI

// MARK: - Task Widget Configuration
struct TaskWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Task List Configuration"
    static var description: IntentDescription = IntentDescription("Configure the task list widget")
    
    @Parameter(title: "Token")
    var tokenID: String?
    
    @Parameter(title: "Database ID")
    var databaseID: String?
    
    @Parameter(title: "Number of Tasks", default: 5)
    var taskCount: Int
    
    @Parameter(title: "Show Completed Tasks", default: false)
    var showCompleted: Bool
}

// MARK: - Progress Widget Configuration
struct ProgressWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Progress Widget Configuration"
    static var description: IntentDescription = IntentDescription("Configure the progress widget")
    
    @Parameter(title: "Token")
    var tokenID: String?
    
    @Parameter(title: "Database ID")
    var databaseID: String?
    
    @Parameter(title: "Title", default: "Progress")
    var title: String
    
    @Parameter(title: "Property for Current Value")
    var currentValueProperty: String?
    
    @Parameter(title: "Property for Target Value")
    var targetValueProperty: String?
    
    @Parameter(title: "Use Percentage", default: true)
    var usePercentage: Bool
}

// MARK: - Token Selection
struct SelectTokenIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Notion Token"
    
    @Parameter(title: "Available Tokens")
    var tokenID: String
    
    init() {
        self.tokenID = ""
    }
    
    init(tokenID: String) {
        self.tokenID = tokenID
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Select \(\.$tokenID)")
    }
    
    // Required by AppIntent protocol
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// Token entity for display and selection in the widget configuration
struct TokenEntity: AppEntity {
    var id: String
    var name: String
    
    static var defaultQuery = TokenQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Notion Token"
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct TokenQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TokenEntity] {
        // Implement fetching specific tokens by ID
        return []
    }
    
    func suggestedEntities() async throws -> [TokenEntity] {
        // Fetch tokens from shared UserDefaults or CoreData
        // This is a placeholder implementation
        return []
    }
}
