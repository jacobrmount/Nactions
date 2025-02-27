import Foundation

public struct NotionQueryDatabaseRequest: Codable {
    public let filter: JSONAny?
    public let sorts: [NotionQuerySort]?
    public let startCursor: String?
    public let pageSize: Int?
    public let filterProperties: [String]?
    
    enum CodingKeys: String, CodingKey {
        case filter, sorts
        case startCursor = "start_cursor"
        case pageSize = "page_size"
        case filterProperties = "filter_properties"
    }
    
    public init(filter: JSONAny? = nil, sorts: [NotionQuerySort]? = nil, startCursor: String? = nil, pageSize: Int? = nil, filterProperties: [String]? = nil) {
        self.filter = filter
        self.sorts = sorts
        self.startCursor = startCursor
        self.pageSize = pageSize
        self.filterProperties = filterProperties
    }
}

public struct NotionQuerySort: Codable {
    public let property: String?
    public let timestamp: String?
    public let direction: String  // "ascending" or "descending"
    
    public init(property: String? = nil, timestamp: String? = nil, direction: String) {
        self.property = property
        self.timestamp = timestamp
        self.direction = direction
    }
}

public struct NotionQueryDatabaseResponse: Codable {
    public let object: String
    public let results: [NotionSearchResult]
    public let nextCursor: String?
    public let hasMore: Bool
    public let type: String
    public let pageOrDatabase: JSONAny?
    
    enum CodingKeys: String, CodingKey {
        case object, results, type, pageOrDatabase = "page_or_database"
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}
