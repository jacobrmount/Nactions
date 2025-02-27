// BusinessLogic/NotionDatabaseModel.swift
import Foundation

/// A simplified version of NotionDatabase with additional metadata for the DatabaseView
struct DatabaseViewModel: Identifiable, Hashable {
    let id: String
    let title: String
    let tokenID: UUID
    let tokenName: String
    var isSelected: Bool
    let lastUpdated: Date
    
    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(tokenID)
    }
    
    static func == (lhs: DatabaseViewModel, rhs: DatabaseViewModel) -> Bool {
        return lhs.id == rhs.id && lhs.tokenID == rhs.tokenID
    }
}

/// A grouping of databases by token
struct TokenDatabaseGroup: Identifiable {
    let id: UUID  // This is the token ID
    let tokenName: String
    var databases: [DatabaseViewModel]
    
    var isConnected: Bool {
        return !databases.isEmpty
    }
}
