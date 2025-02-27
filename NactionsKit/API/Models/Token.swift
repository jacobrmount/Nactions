// DataLayer/Token.swift
import Foundation
import CoreData

@objc(Token)
public class Token: NSManagedObject {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        // Set default values on first insert
        self.id = UUID()
        self.createdDate = Date()
        self.lastUpdatedDate = Date()
        self.isActivated = false // Default to inactive
    }
    
    public override func willSave() {
        super.willSave()
        
        // Check if there are any changes besides lastUpdatedDate.
        let changedKeys = self.changedValues().keys.filter { $0 != "lastUpdatedDate" }
        guard !changedKeys.isEmpty else { return }
        
        // Use primitive setter to update lastUpdatedDate without triggering change notifications.
        let now = Date()
        if abs(now.timeIntervalSince(self.lastUpdatedDate)) < 0.001 {
            // Already nearly up-to-date
            return
        }
        
        self.willChangeValue(forKey: "lastUpdatedDate")
        self.setPrimitiveValue(now, forKey: "lastUpdatedDate")
        self.didChangeValue(forKey: "lastUpdatedDate")
    }
}

public extension Token {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Token> {
        return NSFetchRequest<Token>(entityName: "Token")
    }
    
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var apiToken: String
    @NSManaged var createdDate: Date
    @NSManaged var lastUpdatedDate: Date
    @NSManaged var connectionStatus: Bool
    @NSManaged var isActivated: Bool
    
    func toNotionToken() -> NotionToken {
        return NotionToken(
            id: self.id,
            name: self.name,
            apiToken: self.apiToken,
            isConnected: self.connectionStatus,
            isActivated: self.isActivated
        )
    }
}
