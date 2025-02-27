import Foundation

// MARK: - Minimal Stub Definitions

public enum NotionPropertyValue: Codable {
    case title([NotionRichText])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // For simplicity, assume the property value is always a title.
        let richText = try container.decode([NotionRichText].self)
        self = .title(richText)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .title(let richText):
            try container.encode(richText)
        }
    }
}

public struct NotionIconValue: Codable {
    public let type: String
    public let emoji: String?
    public let externalURL: String?
    
    public init(type: String, emoji: String? = nil, externalURL: String? = nil) {
        self.type = type
        self.emoji = emoji
        self.externalURL = externalURL
    }
}

public struct NotionCoverValue: Codable {
    public let type: String
    public let externalURL: String?
    
    public init(type: String, externalURL: String? = nil) {
        self.type = type
        self.externalURL = externalURL
    }
}

// MARK: - Create Page Models

/// Request model for creating a new page.
public struct NotionCreatePageRequest: Codable {
    public let parent: NotionPageParent
    public let properties: [String: NotionPropertyValue]
    public let children: [NotionBlock]?
    public let icon: NotionIconValue?
    public let cover: NotionCoverValue?
    
    public init(parent: NotionPageParent,
                properties: [String: NotionPropertyValue],
                children: [NotionBlock]? = nil,
                icon: NotionIconValue? = nil,
                cover: NotionCoverValue? = nil) {
        self.parent = parent
        self.properties = properties
        self.children = children
        self.icon = icon
        self.cover = cover
    }
}

/// Parent model for a new page.
public struct NotionPageParent: Codable {
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
