// DataManagement/Entities/Database+Extensions.swift
import Foundation
import CoreData

// Declare the class under our namespace to avoid conflicts
extension CoreData {
    // Typealias to the generated class for cleaner code
    public typealias DatabaseEntity = NactionsKit.DatabaseEntity
}

// Extend the class using the namespace
extension CoreData.DatabaseEntity {
    // Convert from NotionDatabase model to Core Data entity
    public func update(from database: NotionDatabase) {
        self.id = database.id
        self.createdTime = database.createdTime
        self.lastEditedTime = database.lastEditedTime
        self.title = database.title?.first?.plainText ?? "Untitled"
        self.databaseDescription = database.description?.first?.plainText
        self.url = database.url
        self.lastSyncTime = Date()
    }
    
    // Create a new DatabaseEntity from a NotionDatabase model
    public static func create(from database: NotionDatabase, for token: TokenEntity, in context: NSManagedObjectContext) -> DatabaseEntity {
        let newDatabase = DatabaseEntity(context: context)
        newDatabase.id = database.id
        newDatabase.createdTime = database.createdTime
        newDatabase.lastEditedTime = database.lastEditedTime
        newDatabase.title = database.title?.first?.plainText ?? "Untitled"
        newDatabase.databaseDescription = database.description?.first?.plainText
        newDatabase.url = database.url
        newDatabase.lastSyncTime = Date()
        newDatabase.widgetEnabled = false
        newDatabase.token = token
        return newDatabase
    }
    
    // Convert CoreData entity to view model
    public func toDatabaseViewModel() -> DatabaseViewModel {
        let tokenID = self.token.id ?? UUID()
        let tokenName = self.token?.name ?? ""
        
        return DatabaseViewModel(
            id: self.id ?? <#default value#>,
            title: self.title ?? <#default value#>,
            tokenID: tokenID,
            tokenName: tokenName,
            isSelected: self.widgetEnabled,
            lastUpdated: self.lastEditedTime ?? self.lastSyncTime ?? Date()
        )
    }
}
