// DataManagement/Controllers/TokenDataController.swift
import Foundation
import CoreData
import Combine

/// Manages all token-related Core Data operations
public final class TokenDataController {
    /// The shared singleton instance
    public static let shared = TokenDataController()
    
    private init() {}
    
    // MARK: - Fetch Operations
    
    /// Fetches all stored tokens
    public func fetchTokens() -> [TokenEntity] {
        let context = CoreDataStack.shared.viewContext
        let request = NSFetchRequest<TokenEntity>(entityName: "TokenEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching tokens: \(error)")
            return []
        }
    }
    
    /// Fetches tokens as lightweight NotionToken structs
    public func fetchNotionTokens() -> [NotionToken] {
        return fetchTokens().map { $0.toNotionToken() }
    }
    
    /// Fetches activated tokens that are connected
    public func fetchActivatedTokens() -> [TokenEntity] {
        let context = CoreDataStack.shared.viewContext
        let request = NSFetchRequest<TokenEntity>(entityName: "TokenEntity")
        request.predicate = NSPredicate(format: "isActivated == true AND connectionStatus == true")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching activated tokens: \(error)")
            return []
        }
    }
    
    /// Fetches activated tokens as lightweight NotionToken structs
    public func fetchActivatedNotionTokens() -> [NotionToken] {
        return fetchActivatedTokens().map { $0.toNotionToken() }
    }
    
    /// Fetches a specific token by ID
    public func fetchToken(id: UUID) -> TokenEntity? {
        let context = CoreDataStack.shared.viewContext
        let request = NSFetchRequest<TokenEntity>(entityName: "TokenEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching token with ID \(id): \(error)")
            return nil
        }
    }
    
    // MARK: - Create/Update Operations
    
    /// Saves a new token with the given name and API token
    @discardableResult
    public func saveToken(name: String, apiToken: String) -> TokenEntity? {
        let context = CoreDataStack.shared.viewContext
        let newToken = TokenEntity(context: context)
        newToken.id = UUID()
        newToken.name = name
        newToken.apiToken = apiToken
        newToken.connectionStatus = false
        newToken.isActivated = false
        newToken.createdDate = Date()
        newToken.lastUpdatedDate = Date()
        
        do {
            try context.save()
            return newToken
        } catch {
            print("Error saving token: \(error)")
            return nil
        }
    }
    
    /// Updates an existing token with new values
    public func updateToken(id: UUID, name: String, apiToken: String, isConnected: Bool, isActivated: Bool, workspaceInfo: (id: String, name: String)? = nil) {
        let context = CoreDataStack.shared.viewContext
        let request = NSFetchRequest<TokenEntity>(entityName: "TokenEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let token = try context.fetch(request).first {
                token.name = name
                token.apiToken = apiToken
                token.connectionStatus = isConnected
                token.isActivated = isActivated
                token.lastUpdatedDate = Date()
                
                if let workspaceInfo = workspaceInfo {
                    token.workspaceID = workspaceInfo.id
                    token.workspaceName = workspaceInfo.name
                }
                
                try context.save()
            }
        } catch {
            print("Error updating token with ID \(id): \(error)")
        }
    }
    
    /// Updates a token from a NotionToken struct
    public func updateToken(from notionToken: NotionToken) {
        updateToken(
            id: notionToken.id,
            name: notionToken.name,
            apiToken: notionToken.apiToken,
            isConnected: notionToken.isConnected,
            isActivated: notionToken.isActivated,
            workspaceInfo: notionToken.workspaceID != nil && notionToken.workspaceName != nil ?
                (notionToken.workspaceID!, notionToken.workspaceName!) : nil
        )
    }
    
    /// Toggle activation status for a token
    public func toggleTokenActivation(tokenID: UUID, isActivated: Bool) {
        let context = CoreDataStack.shared.viewContext
        let request = NSFetchRequest<TokenEntity>(entityName: "TokenEntity")
        request.predicate = NSPredicate(format: "id == %@", tokenID as CVarArg)
        
        do {
            if let token = try context.fetch(request).first {
                // Only allow activating connected tokens
                if isActivated && !token.connectionStatus {
                    print("Cannot activate disconnected token")
                    return
                }
                
                token.isActivated = isActivated
                try context.save()
                print("Token activation status updated to: \(isActivated)")
            } else {
                print("Token with ID \(tokenID) not found for activation update")
            }
        } catch {
            print("Error updating token activation: \(error)")
        }
    }
    
    // MARK: - Delete Operations
    
    /// Deletes a token by ID
    public func deleteToken(id: UUID) {
        let context = CoreDataStack.shared.viewContext
        let request = NSFetchRequest<TokenEntity>(entityName: "TokenEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let token = try context.fetch(request).first {
                context.delete(token)
                try context.save()
                print("Token deleted successfully")
            } else {
                print("Token with ID \(id) not found for deletion")
            }
        } catch {
            print("Error deleting token: \(error)")
        }
    }
    
    /// Deletes a token from a NotionToken struct
    public func deleteToken(_ token: NotionToken) {
        deleteToken(id: token.id)
    }
    
    // MARK: - Batch Operations
    
    /// Updates connection status for multiple tokens
    public func updateConnectionStatus(for tokens: [TokenEntity], status: Bool) {
        let context = CoreDataStack.shared.viewContext
        let tokenIDs = tokens.compactMap { $0.id }
        let request = NSFetchRequest<TokenEntity>(entityName: "TokenEntity")
        request.predicate = NSPredicate(format: "id IN %@", tokenIDs)
        
        do {
            let tokensToUpdate = try context.fetch(request)
            for token in tokensToUpdate {
                token.connectionStatus = status
                
                // If disconnected, also deactivate
                if !status && token.isActivated {
                    token.isActivated = false
                }
            }
            
            try context.save()
        } catch {
            print("Error updating connection status: \(error)")
        }
    }
    
    /// Imports tokens from a backup
    public func importTokens(_ tokens: [NotionToken]) {
        let context = CoreDataStack.shared.viewContext
        
        for tokenModel in tokens {
            // Check if token with this ID already exists
            let request = NSFetchRequest<TokenEntity>(entityName: "TokenEntity")
            request.predicate = NSPredicate(format: "id == %@", tokenModel.id as CVarArg)
            
            do {
                let existingTokens = try context.fetch(request)
                
                if let existingToken = existingTokens.first {
                    // Update existing token
                    existingToken.name = tokenModel.name
                    existingToken.apiToken = tokenModel.apiToken
                    existingToken.connectionStatus = false // Force validation on import
                    existingToken.isActivated = false // Force reactivation on import
                    existingToken.lastUpdatedDate = Date()
                } else {
                    // Create new token
                    let newToken = TokenEntity(context: context)
                    newToken.id = tokenModel.id
                    newToken.name = tokenModel.name
                    newToken.apiToken = tokenModel.apiToken
                    newToken.connectionStatus = false
                    newToken.isActivated = false
                    newToken.createdDate = Date()
                    newToken.lastUpdatedDate = Date()
                }
            } catch {
                print("Error importing token: \(error)")
            }
        }
        
        do {
            try context.save()
            print("Tokens imported successfully")
        } catch {
            print("Error saving imported tokens: \(error)")
        }
    }
}
