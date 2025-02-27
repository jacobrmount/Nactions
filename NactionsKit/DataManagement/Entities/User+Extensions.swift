// DataManagement/Entities/User+Extensions.swift
import Foundation
import CoreData

extension UserEntity {
    /// Converts to NotionUser for API operations
    func toNotionUser() -> NotionUser {
        return NotionUser(
            object: "user",
            id: self.id ?? "",
            name: self.name,
            email: self.email,
            type: self.type
        )
    }
    
    /// Updates from NotionUser model
    func update(from user: NotionUser) {
        self.id = user.id
        self.name = user.name
        self.email = user.email
        self.type = user.type ?? "unknown"
        self.lastSyncTime = Date()
    }
    
    /// Creates UserEntity from NotionUser
    static func create(from user: NotionUser, in context: NSManagedObjectContext) -> UserEntity {
        let entity = UserEntity(context: context)
        entity.id = user.id
        entity.name = user.name
        entity.email = user.email
        entity.type = user.type ?? "unknown"
        entity.lastSyncTime = Date()
        return entity
    }
}
