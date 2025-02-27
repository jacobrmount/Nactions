// DataManagement/Controllers/UserDataController.swift
import Foundation
import CoreData

public final class UserDataController {
    public static let shared = UserDataController()
    
    private init() {}
    
    public func fetchUser(id: String) -> CoreData.UserEntity? {
        let context = CoreDataStack.shared.viewContext
        let request: NSFetchRequest<CoreData.UserEntity> = CoreData.UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching user: \(error)")
            return nil
        }
    }
    
    public func saveUser(from notionUser: NotionUser) -> CoreData.UserEntity? {
        let context = CoreDataStack.shared.viewContext
        
        // Check if user already exists
        if let existingUser = fetchUser(id: notionUser.id) {
            existingUser.name = notionUser.name
            existingUser.email = notionUser.email
            existingUser.type = notionUser.type ?? "unknown"
            existingUser.lastSyncTime = Date()
            
            do {
                try context.save()
                return existingUser
            } catch {
                print("Error updating user: \(error)")
                return nil
            }
        }
        
        // Create new user
        let newUser = CoreData.UserEntity.create(from: notionUser, in: context)
        
        do {
            try context.save()
            return newUser
        } catch {
            print("Error saving new user: \(error)")
            return nil
        }
    }
}
