// DataManagement/Entities/Token+Extensions.swift
import Foundation
import CoreData

extension TokenEntity {
    /// Converts this managed object to a NotionToken model for API operations
    func toNotionToken() -> NotionToken {
        return NotionToken(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            apiToken: self.apiToken ?? "",
            isConnected: self.connectionStatus,
            isActivated: self.isActivated,
            workspaceID: self.workspaceID,
            workspaceName: self.workspaceName
        )
    }
    
    /// Updates this managed object from a NotionToken model
    func update(from token: NotionToken) {
        self.id = token.id
        self.name = token.name
        self.apiToken = token.apiToken
        self.connectionStatus = token.isConnected
        self.isActivated = token.isActivated
        self.workspaceID = token.workspaceID
        self.workspaceName = token.workspaceName
        self.lastUpdatedDate = Date()
    }
    
    /// Creates a new Token managed object from a NotionToken model
    static func create(from token: NotionToken, in context: NSManagedObjectContext) -> TokenEntity {
        let newToken = TokenEntity(context: context)
        newToken.id = token.id
        newToken.name = token.name
        newToken.apiToken = token.apiToken
        newToken.connectionStatus = token.isConnected
        newToken.isActivated = token.isActivated
        newToken.workspaceID = token.workspaceID
        newToken.workspaceName = token.workspaceName
        newToken.createdDate = Date()
        newToken.lastUpdatedDate = Date()
        return newToken
    }
}
