import Foundation

/// Request model for updating a database.
/// All fields are optional; omit a field to leave it unchanged.
public struct NotionUpdateDatabaseRequest: Codable {
    public let title: [NotionRichText]?
    public let description: [NotionRichText]?  // New optional property for database description.
    public let properties: [String: NotionUpdatePropertySchema]?
    public let cover: NotionCoverValue?
    public let icon: NotionIconValue?
    
    public init(title: [NotionRichText]? = nil,
                description: [NotionRichText]? = nil,
                properties: [String: NotionUpdatePropertySchema]? = nil,
                cover: NotionCoverValue? = nil,
                icon: NotionIconValue? = nil) {
        self.title = title
        self.description = description
        self.properties = properties
        self.cover = cover
        self.icon = icon
    }
}

/// A minimal implementation for updating a database property schema.
/// Use the `name` field to rename a property.
public struct NotionUpdatePropertySchema: Codable {
    public let name: String?
    
    public init(name: String? = nil) {
        self.name = name
    }
}
