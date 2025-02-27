// DataManagement/CoreDataStack.swift
import Foundation
import CoreData

/// Manages Core Data operations and shared context
public final class CoreDataStack {
    /// The shared singleton instance
    public static let shared = CoreDataStack()
    
    /// The persistent container for the Core Data stack
    public let persistentContainer: NSPersistentContainer
    
    /// The main view context for UI operations
    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    /// A background context for operations that don't need to update the UI
    public var backgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    private init() {
        // Initialize the persistent container with our data model
        persistentContainer = NSPersistentContainer(name: "NactionsDataModel")
        
        // Set the store URL to the shared app group container for widget access
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nactions") {
            let storeURL = appGroupURL.appendingPathComponent("NactionsDataModel.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            persistentContainer.persistentStoreDescriptions = [description]
        }
        
        // Load the persistent stores
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // This is a severe error that prevents the app from functioning correctly
                fatalError("Failed to load persistent stores: \(error), \(error.userInfo)")
            }
        }
        
        // Configure the view context for automatic merging of changes
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    /// Saves changes in the view context if there are any
    public func saveViewContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving view context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /// Performs a task on a background context and saves when complete
    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { context in
            block(context)
            
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nsError = error as NSError
                    print("Error saving background context: \(nsError), \(nsError.userInfo)")
                }
            }
        }
    }
    
    /// Performs a task on a background context and returns a result
    public func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    
                    if context.hasChanges {
                        do {
                            try context.save()
                        } catch {
                            continuation.resume(throwing: error)
                            return
                        }
                    }
                    
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
