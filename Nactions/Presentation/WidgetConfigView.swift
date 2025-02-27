// Nactions/Presentation/WidgetConfigView.swift
import SwiftUI
import WidgetKit

struct WidgetConfigView: View {
    @ObservedObject var tokenService = TokenService.shared
    @State private var selectedTokenID: UUID?
    @State private var selectedDatabaseID: String = ""
    @State private var isLoadingDatabases: Bool = false
    @State private var databases: [(id: String, name: String)] = []
    @State private var selectedWidgetType: WidgetType = .taskList
    @State private var configuringMessage: String?
    
    // Task List specific configuration
    @State private var taskCount: Int = 5
    @State private var showCompletedTasks: Bool = false
    
    // Progress specific configuration
    @State private var progressTitle: String = "Progress"
    @State private var currentValueProperty: String = ""
    @State private var targetValueProperty: String = ""
    @State private var properties: [String] = []
    @State private var isLoadingProperties: Bool = false
    
    enum WidgetType: String, CaseIterable, Identifiable {
        case taskList = "Task List"
        case progress = "Progress"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Widget Type Selection
                Section(header: Text("Widget Type")) {
                    Picker("Widget Type", selection: $selectedWidgetType) {
                        ForEach(WidgetType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Token Selection
                Section(header: Text("Notion Token")) {
                    if tokenService.tokens.isEmpty {
                        Text("No tokens available. Please add a token first.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Select Token", selection: $selectedTokenID) {
                            Text("Select a token").tag(nil as UUID?)
                            ForEach(tokenService.tokens) { token in
                                HStack {
                                    Circle()
                                        .fill(token.isConnected ? Color.green : Color.red)
                                        .frame(width: 10, height: 10)
                                    Text(token.name).tag(token.id as UUID?)
                                }
                            }
                        }
                        .onChange(of: selectedTokenID) { oldValue, newValue in
                            if let tokenID = newValue {
                                loadDatabases(for: tokenID)
                            } else {
                                databases = []
                                selectedDatabaseID = ""
                            }
                        }
                    }
                }
                
                // Database Selection
                if let _ = selectedTokenID {
                    Section(header: Text("Notion Database")) {
                        if isLoadingDatabases {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else if databases.isEmpty {
                            Text("No databases found. Please refresh.")
                                .foregroundColor(.secondary)
                        } else {
                            Picker("Select Database", selection: $selectedDatabaseID) {
                                Text("Select a database").tag("")
                                ForEach(databases, id: \.id) { database in
                                    Text(database.name).tag(database.id)
                                }
                            }
                            .onChange(of: selectedDatabaseID) { oldValue, newValue in
                                if !newValue.isEmpty && selectedWidgetType == .progress {
                                    loadDatabaseProperties(for: newValue)
                                }
                            }
                        }
                        
                        Button(action: {
                            if let tokenID = selectedTokenID {
                                loadDatabases(for: tokenID)
                            }
                        }) {
                            Label("Refresh Databases", systemImage: "arrow.clockwise")
                        }
                    }
                }
                
                // Widget Specific Configuration
                if !selectedDatabaseID.isEmpty {
                    switch selectedWidgetType {
                    case .taskList:
                        Section(header: Text("Task List Configuration")) {
                            Stepper("Number of Tasks: \(taskCount)", value: $taskCount, in: 1...10)
                            Toggle("Show Completed Tasks", isOn: $showCompletedTasks)
                        }
                    case .progress:
                        Section(header: Text("Progress Configuration")) {
                            TextField("Title", text: $progressTitle)
                            
                            if isLoadingProperties {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else if properties.isEmpty {
                                Text("No properties found. Please select a different database.")
                                    .foregroundColor(.secondary)
                            } else {
                                Picker("Current Value Property", selection: $currentValueProperty) {
                                    Text("Select a property").tag("")
                                    ForEach(properties, id: \.self) { property in
                                        Text(property).tag(property)
                                    }
                                }
                                
                                Picker("Target Value Property", selection: $targetValueProperty) {
                                    Text("Select a property").tag("")
                                    ForEach(properties, id: \.self) { property in
                                        Text(property).tag(property)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Create Widget Button
                if canCreateWidget {
                    Section {
                        Button(action: {
                            configureWidget()
                        }) {
                            Text("Save Widget Configuration")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .navigationTitle("Widget Configuration")
            .overlay(
                Group {
                    if let message = configuringMessage {
                        VStack {
                            Spacer()
                            Text(message)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding()
                            Spacer()
                        }
                    }
                }
            )
        }
    }
    
    // Check if we have all required info to create the widget
    private var canCreateWidget: Bool {
        guard let _ = selectedTokenID, !selectedDatabaseID.isEmpty else {
            return false
        }
        
        switch selectedWidgetType {
        case .taskList:
            return true
        case .progress:
            return !progressTitle.isEmpty && !currentValueProperty.isEmpty && !targetValueProperty.isEmpty
        }
    }
    
    // Fetch databases for the selected token
    private func loadDatabases(for tokenID: UUID) {
        isLoadingDatabases = true
        databases = []
        selectedDatabaseID = ""
        
        Task {
            await WidgetDataManager.shared.refreshDatabasesForWidget(tokenID: tokenID)
            
            // Get the cached databases from shared UserDefaults
            if let userDefaults = UserDefaults(suiteName: AppGroupConfig.appGroupIdentifier),
               let cachedDatabases = userDefaults.array(forKey: "nactions_databases_\(tokenID.uuidString)") as? [[String: Any]] {
                
                let mappedDatabases = cachedDatabases.compactMap { database -> (id: String, name: String)? in
                    guard let id = database["id"] as? String,
                          let title = database["title"] as? String else {
                        return nil
                    }
                    return (id: id, name: title)
                }
                
                DispatchQueue.main.async {
                    self.databases = mappedDatabases
                    self.isLoadingDatabases = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoadingDatabases = false
                }
            }
        }
    }
    
    // Fetch database properties for progress widget
    private func loadDatabaseProperties(for databaseID: String) {
        guard let tokenID = selectedTokenID else { return }
        
        isLoadingProperties = true
        properties = []
        
        Task {
            guard let token = tokenService.tokens.first(where: { $0.id == tokenID }) else {
                DispatchQueue.main.async {
                    self.isLoadingProperties = false
                }
                return
            }
            
            do {
                let client = NotionAPIClient(token: token.apiToken)
                let database = try await client.retrieveDatabase(databaseID: databaseID)
                
                // For the properties, we would need to extract them from the database
                // This is a placeholder - in a real implementation, you would:
                // 1. Extract the properties from database.properties
                // 2. Filter for number properties only (for progress widgets)
                
                // For now, use sample property names
                DispatchQueue.main.async {
                    self.properties = ["Completed", "Total", "Progress", "Count"]
                    self.isLoadingProperties = false
                }
            } catch {
                print("Error fetching database properties: \(error)")
                DispatchQueue.main.async {
                    self.isLoadingProperties = false
                }
            }
        }
    }
    
    // Configure and save widget settings
    private func configureWidget() {
        guard let tokenID = selectedTokenID else { return }
        
        configuringMessage = "Configuring widget..."
        
        Task {
            // Perform initial data fetch for the widget
            switch selectedWidgetType {
            case .taskList:
                await WidgetDataManager.shared.fetchAndCacheTasks(
                    tokenID: tokenID,
                    databaseID: selectedDatabaseID
                )
                
                // Store widget configuration in user defaults
                if let userDefaults = UserDefaults(suiteName: AppGroupConfig.appGroupIdentifier) {
                    let config: [String: Any] = [
                        "tokenID": tokenID.uuidString,
                        "databaseID": selectedDatabaseID,
                        "taskCount": taskCount,
                        "showCompleted": showCompletedTasks
                    ]
                    userDefaults.set(config, forKey: "widget_config_taskList")
                }
                
                // Refresh widgets
                WidgetCenter.shared.reloadTimelines(ofKind: "TaskListWidget")
                
            case .progress:
                await WidgetDataManager.shared.fetchAndCacheProgress(
                    tokenID: tokenID,
                    databaseID: selectedDatabaseID,
                    title: progressTitle,
                    currentValueProperty: currentValueProperty,
                    targetValueProperty: targetValueProperty
                )
                
                // Store widget configuration in user defaults
                if let userDefaults = UserDefaults(suiteName: AppGroupConfig.appGroupIdentifier) {
                    let config: [String: Any] = [
                        "tokenID": tokenID.uuidString,
                        "databaseID": selectedDatabaseID,
                        "title": progressTitle,
                        "currentValueProperty": currentValueProperty,
                        "targetValueProperty": targetValueProperty
                    ]
                    userDefaults.set(config, forKey: "widget_config_progress")
                }
                
                // Refresh widgets
                WidgetCenter.shared.reloadTimelines(ofKind: "ProgressWidget")
            }
            
            // Update UI
            DispatchQueue.main.async {
                self.configuringMessage = "Widget configured! Add it to your home screen from the widget gallery."
                
                // Clear the message after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.configuringMessage = nil
                }
            }
        }
    }
}
