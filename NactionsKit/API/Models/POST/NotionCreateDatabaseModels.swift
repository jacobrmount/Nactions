import Foundation

/// Request model for creating a new database.
public struct NotionCreateDatabaseRequest: Codable {
    public let parent: NotionDatabaseParent
    public let title: [NotionRichText]
    public let properties: [String: NotionPropertySchema]
    public let icon: NotionIconValue?
    public let cover: NotionCoverValue?
    
    public init(parent: NotionDatabaseParent,
                title: [NotionRichText],
                properties: [String: NotionPropertySchema],
                icon: NotionIconValue? = nil,
                cover: NotionCoverValue? = nil) {
        self.parent = parent
        self.title = title
        self.properties = properties
        self.icon = icon
        self.cover = cover
    }
}

/// A minimal stub for a property schema. Replace with your full implementation if needed.
public struct NotionPropertySchema: Codable {}

/// A type representing the parent for a new database.
/// Renamed to `NotionDatabaseParent` to avoid conflict with other definitions.
public struct NotionDatabaseParent: Codable {
    public let pageID: String?
    public let databaseID: String?
    
    enum CodingKeys: String, CodingKey {
        case pageID = "page_id"
        case databaseID = "database_id"
    }
    
    public init(pageID: String) {
        self.pageID = pageID
        self.databaseID = nil
    }
    
    public init(databaseID: String) {
        self.pageID = nil
        self.databaseID = databaseID
    }
}
