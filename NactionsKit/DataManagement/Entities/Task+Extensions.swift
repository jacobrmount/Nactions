// DataManagement/Entities/Task+Extensions.swift
import Foundation
import CoreData

// Declare the class under our namespace to avoid conflicts
extension CoreData {
    // Typealias to the generated class for cleaner code
    public typealias TaskEntity = NactionsKit.TaskEntity
}

// Extend the class using the namespace
extension CoreData.TaskEntity {
    // Lifecycle methods
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.lastSyncTime = Date()
    }
    
    // Convenience methods
    
    // Convert to TaskItem for widget display
    public func toTaskItem() -> TaskItem {
        return TaskItem(
            id: self.id ?? "",
            title: self.title ?? "Untitled Task",
            isCompleted: self.isCompleted,
            dueDate: self.dueDate
        )
    }
    
    // Update from a TaskItem
    public func update(from taskItem: TaskItem) {
        self.id = taskItem.id
        self.title = taskItem.title
        self.isCompleted = taskItem.isCompleted
        self.dueDate = taskItem.dueDate
        self.lastSyncTime = Date()
    }
    
    // Create a new Task managed object from a TaskItem
    public static func create(from taskItem: TaskItem,
                              databaseID: String,
                              pageID: String,
                              tokenID: UUID,
                              in context: NSManagedObjectContext) -> CoreData.TaskEntity {
        let newTask = TaskEntity(context: context)
        newTask.id = taskItem.id
        newTask.title = taskItem.title
        newTask.isCompleted = taskItem.isCompleted
        newTask.dueDate = taskItem.dueDate
        newTask.pageID = pageID
        newTask.databaseID = databaseID
        newTask.tokenID = tokenID
        newTask.lastSyncTime = Date()
        return newTask
    }
}
