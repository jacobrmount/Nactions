// BusinessLogic/DatabaseService.swift
import Foundation
import Combine
import WidgetKit

@MainActor
class DatabaseService: ObservableObject {
    static let shared = DatabaseService()
    
    @Published var databaseGroups: [TokenDatabaseGroup] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to changes in activated tokens
        TokenService.shared.$activatedTokens
            .sink { [weak self] _ in
                Task {
                    await self?.refreshDatabases()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Refreshes databases for all activated tokens
    func refreshDatabases() async {
        isLoading = true
        errorMessage = nil
        
        let activatedTokens = TokenService.shared.activatedTokens
        print("Refreshing databases for \(activatedTokens.count) activated tokens")
        
        if activatedTokens.isEmpty {
            databaseGroups = []
            isLoading = false
            return
        }
        
        var newGroups: [TokenDatabaseGroup] = []
        
        for token in activatedTokens {
            print("Processing token: \(token.name), is connected: \(token.isConnected)")
            do {
                let databases = try await fetchDatabases(for: token)
                let viewModels = databases.map { database -> DatabaseViewModel in
                    // Check if this database was previously selected
                    let wasSelected = self.databaseGroups
                        .first(where: { $0.id == token.id })?
                        .databases
                        .first(where: { $0.id == database.id })?
                        .isSelected ?? false
                    
                    return DatabaseViewModel(
                        id: database.id,
                        title: database.title?.first?.plainText ?? "Untitled",
                        tokenID: token.id,
                        tokenName: token.name,
                        isSelected: wasSelected,
                        lastUpdated: database.lastEditedTime ?? Date()
                    )
                }
                
                let group = TokenDatabaseGroup(
                    id: token.id,
                    tokenName: token.name,
                    databases: viewModels
                )
                
                print("Adding group for token \(token.name) with \(viewModels.count) databases")
                newGroups.append(group)
            } catch {
                print("Error fetching databases for token \(token.name): \(error)")
                errorMessage = "Failed to fetch databases for \(token.name): \(error.localizedDescription)"
            }
        }
        
        DispatchQueue.main.async {
            self.databaseGroups = newGroups
            self.isLoading = false
            print("Updated database groups: \(newGroups.count)")
            for group in newGroups {
                print("Group: \(group.tokenName) - \(group.databases.count) databases")
            }
        }
    }
    
    /// Fetches databases for a specific token
    private func fetchDatabases(for token: NotionToken) async throws -> [NotionDatabase] {
        let client = NotionAPIClient(token: token.apiToken)
        
        // Create a search filter for databases
        let filter = NotionSearchFilter(property: "object", value: "database")
        
        // First try to search with no query (gets all databases)
        let searchResults = try await client.searchByTitle(
            filter: filter,
            pageSize: 100
        )
        
        // Fetch full database details for each result
        var databases: [NotionDatabase] = []
        
        for result in searchResults.results where result.object == "database" {
            do {
                let database = try await client.retrieveDatabase(databaseID: result.id)
                
                // Print database details for debugging
                print("Found database: \(database.id), title: \(database.title?.first?.plainText ?? "Untitled")")
                
                databases.append(database)
            } catch {
                print("Error fetching database \(result.id): \(error)")
                // Continue with other databases even if one fails
            }
        }
        
        // Log the results
        print("Total databases found for token \(token.name): \(databases.count)")
        
        return databases
    }
    
    /// Toggles selection state for a database
    func toggleDatabaseSelection(databaseID: String, tokenID: UUID) {
        guard let groupIndex = databaseGroups.firstIndex(where: { $0.id == tokenID }),
              let dbIndex = databaseGroups[groupIndex].databases.firstIndex(where: { $0.id == databaseID }) else {
            return
        }
        
        databaseGroups[groupIndex].databases[dbIndex].isSelected.toggle()
        
        // Update WidgetDataManager with selected databases
        updateSelectedDatabases()
    }
    
    /// Gets all selected databases
    func getSelectedDatabases() -> [DatabaseViewModel] {
        return databaseGroups.flatMap { group in
            group.databases.filter { $0.isSelected }
        }
    }
    
    /// Updates the WidgetDataManager with the current selection
    private func updateSelectedDatabases() {
        let selectedDatabases = getSelectedDatabases()
        
        // Save selection to UserDefaults for persistence
        if let userDefaults = UserDefaults(suiteName: "group.com.nactions") {
            let selectedDatabaseData = selectedDatabases.map { db -> [String: Any] in
                return [
                    "id": db.id,
                    "title": db.title,
                    "tokenID": db.tokenID.uuidString
                ]
            }
            
            userDefaults.set(selectedDatabaseData, forKey: "selected_databases")
        }
        
        // Notify WidgetCenter to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
}
