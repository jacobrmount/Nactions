// DataManagement/Entities/Page+Extensions.swift
import Foundation
import CoreData

extension PageEntity {
    /// Converts this managed object to a NotionPage model for API operations
    func toNotionPage() -> NotionPage {
        // Create a parent object based on the available parent ID
        let parent: NotionParent?
        if let parentDatabaseID = self.parentDatabaseID {
            parent = NotionParent(type: "database_id", databaseID: parentDatabaseID)
        } else if let parentPageID = self.parentPageID {
            // Note: This isn't completely accurate to your existing model structure
            // You might need to adjust based on how you handle page parents
            parent = NotionParent(type: "page_id", databaseID: parentPageID)
        } else {
            parent = nil
        }
        
        // Create an empty properties dictionary
        // Note: We'd need to convert property entities to the format expected by NotionPage
        // This is a placeholder - you would implement property conversion based on your needs
        let properties: [String: JSONAny] = [:]
        
        return NotionPage(
            object: "page",
            id: self.id ?? "",
            createdTime: self.createdTime,
            lastEditedTime: self.lastEditedTime,
            createdBy: nil, // We don't store creator info in our model
            lastEditedBy: nil, // We don't store editor info in our model
            cover: nil, // We don't store cover info in our model
            icon: nil, // We don't store icon info in our model
            parent: parent,
            archived: self.archived,
            properties: properties,
            url: self.url
        )
    }
    
    /// Updates this managed object from a NotionPage model
    func update(from page: NotionPage) {
        self.id = page.id
        self.createdTime = page.createdTime
        self.lastEditedTime = page.lastEditedTime
        self.archived = page.archived ?? false
        self.url = page.url
        self.lastSyncTime = Date()
        
        // Update title from properties
        if let titleProperty = page.properties?.first(where: { $0.key.lowercased().contains("title") }) {
            if let titleValue = titleProperty.value.value as? [Any],
               let firstTitle = titleValue.first as? [String: Any],
               let text = firstTitle["text"] as? [String: Any],
               let content = text["content"] as? String {
                self.title = content
            }
        }
        
        // Update parent references
        if let parent = page.parent {
            if parent.type == "database_id" {
                self.parentDatabaseID = parent.databaseID
                self.parentPageID = nil
            } else if parent.type == "page_id" {
                self.parentPageID = parent.databaseID // Using databaseID for pageID (model mismatch)
                self.parentDatabaseID = nil
            }
        }
        
        // Update properties - this would require more complex implementation
        // For each property in the page, we'd need to create/update Property entities
    }
    
    /// Creates a new Page managed object from a NotionPage model
    static func create(from page: NotionPage, in context: NSManagedObjectContext) -> PageEntity {
        let newPage = PageEntity(context: context)
        newPage.id = page.id
        newPage.createdTime = page.createdTime
        newPage.lastEditedTime = page.lastEditedTime
        newPage.archived = page.archived ?? false
        newPage.url = page.url
        newPage.lastSyncTime = Date()
        
        // Set title from properties
        if let titleProperty = page.properties?.first(where: { $0.key.lowercased().contains("title") }) {
            if let titleValue = titleProperty.value.value as? [Any],
               let firstTitle = titleValue.first as? [String: Any],
               let text = firstTitle["text"] as? [String: Any],
               let content = text["content"] as? String {
                newPage.title = content
            } else {
                newPage.title = "Untitled"
            }
        } else {
            newPage.title = "Untitled"
        }
        
        // Set parent references
        if let parent = page.parent {
            if parent.type == "database_id" {
                newPage.parentDatabaseID = parent.databaseID
                
                // If we have a database ID, try to find and link the database
                if let databaseID = parent.databaseID {
                    let fetchRequest = NSFetchRequest<DatabaseEntity>(entityName: "DatabaseEntity")
                    fetchRequest.predicate = NSPredicate(format: "id == %@", databaseID)
                    do {
                        if let database = try context.fetch(fetchRequest).first {
                            newPage.database = database
                        }
                    } catch {
                        print("Error linking page to database: \(error)")
                    }
                }
            } else if parent.type == "page_id" {
                newPage.parentPageID = parent.databaseID // Using databaseID for pageID (model mismatch)
            }
        }
        
        return newPage
    }
    
    /// Converts this page to a TaskItem for widget display
    func toTaskItem() -> TaskItem? {
        // This assumes the page represents a task with a status property
        // Use helpers to extract task-related information
        
        return TaskItem(
            id: self.id ?? "",
            title: self.title ?? "Untitled Task",
            isCompleted: self.getCompletionStatus() ?? false,
            dueDate: self.getDueDate()
        )
    }
    
    // MARK: - Helper Methods
    
    /// Gets a property where name contains one of the given terms
    func getProperty(whereNameContains terms: [String]) -> PropertyEntity? {
        guard let properties = self.properties as? Set<PropertyEntity> else { return nil }
        
        return properties.first { property in
            guard let name = property.name else { return false }
            return terms.contains { term in
                name.lowercased().contains(term.lowercased())
            }
        }
    }
    
    /// Gets the completion status from a boolean property
    func getCompletionStatus() -> Bool? {
        let statusProperty = getProperty(whereNameContains: ["status", "complete", "done"])
        // Implement extraction of boolean value from property
        return false // Default implementation
    }
    
    /// Gets the due date from a date property
    func getDueDate() -> Date? {
        let dueDateProperty = getProperty(whereNameContains: ["due", "date"])
        // Implement extraction of date value from property
        return nil // Default implementation
    }
}
