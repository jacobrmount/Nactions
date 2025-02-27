import Foundation

/// The search response returned by the Notion API.
public struct NotionSearchResponse: Codable {
    public let object: String
    public let results: [NotionSearchResult]
    public let nextCursor: String?
    public let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case object, results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

/// A unified search result representing either a page or a database.
/// (For simplicity, this model currently includes only common fields.)
public struct NotionSearchResult: Codable {
    public let object: String
    public let id: String
    // Additional common properties can be added here.
}

/// Model for the sort criteria.
public struct NotionSearchSort: Codable {
    /// The direction to sort: "ascending" or "descending".
    public let direction: String
    /// The timestamp field to sort by. Only "last_edited_time" is supported.
    public let timestamp: String
    
    public var dictionary: [String: Any] {
        return [
            "direction": direction,
            "timestamp": timestamp
        ]
    }
}

/// Model for the filter criteria.
public struct NotionSearchFilter: Codable {
    /// The property to filter by (currently only "object" is supported).
    public let property: String
    /// The value to filter for ("page" or "database").
    public let value: String
    
    public var dictionary: [String: Any] {
        return [
            "property": property,
            "value": value
        ]
    }
}
