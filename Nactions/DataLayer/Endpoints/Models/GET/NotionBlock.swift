import Foundation

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { return nil }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

public struct NotionBlockParent: Codable {
    public let type: String
    public let pageID: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case pageID = "page_id"
    }
}

public struct NotionBlock: Codable {
    public let object: String
    public let id: String
    public let parent: NotionBlockParent?
    public let createdTime: Date?
    public let lastEditedTime: Date?
    public let createdBy: NotionUser?
    public let lastEditedBy: NotionUser?
    public let hasChildren: Bool
    public let archived: Bool
    public let type: String
    public let blockContent: JSONAny?
    
    enum CodingKeys: String, CodingKey {
        case object, id, parent
        case createdTime = "created_time"
        case lastEditedTime = "last_edited_time"
        case createdBy = "created_by"
        case lastEditedBy = "last_edited_by"
        case hasChildren = "has_children"
        case archived, type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        object = try container.decode(String.self, forKey: .object)
        id = try container.decode(String.self, forKey: .id)
        parent = try container.decodeIfPresent(NotionBlockParent.self, forKey: .parent)
        createdTime = try container.decodeIfPresent(Date.self, forKey: .createdTime)
        lastEditedTime = try container.decodeIfPresent(Date.self, forKey: .lastEditedTime)
        createdBy = try container.decodeIfPresent(NotionUser.self, forKey: .createdBy)
        lastEditedBy = try container.decodeIfPresent(NotionUser.self, forKey: .lastEditedBy)
        hasChildren = try container.decode(Bool.self, forKey: .hasChildren)
        archived = try container.decode(Bool.self, forKey: .archived)
        type = try container.decode(String.self, forKey: .type)
        
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        if let dynamicKey = DynamicCodingKey(stringValue: type) {
            blockContent = try dynamicContainer.decodeIfPresent(JSONAny.self, forKey: dynamicKey)
        } else {
            blockContent = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(object, forKey: .object)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(parent, forKey: .parent)
        try container.encodeIfPresent(createdTime, forKey: .createdTime)
        try container.encodeIfPresent(lastEditedTime, forKey: .lastEditedTime)
        try container.encodeIfPresent(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(lastEditedBy, forKey: .lastEditedBy)
        try container.encode(hasChildren, forKey: .hasChildren)
        try container.encode(archived, forKey: .archived)
        try container.encode(type, forKey: .type)
        
        if let blockContent = blockContent, let dynamicKey = DynamicCodingKey(stringValue: type) {
            var dynamicContainer = encoder.container(keyedBy: DynamicCodingKey.self)
            try dynamicContainer.encode(blockContent, forKey: dynamicKey)
        }
    }
}

public extension NotionBlock {
    /// Returns the heading_2 data as a NotionUpdateHeading2 instance if available.
    var heading2: NotionUpdateHeading2? {
        guard self.type == "heading_2", let content = blockContent?.value else {
            return nil
        }
        // Sanitize the content by replacing JSONNull instances with NSNull.
        let sanitizedContent = sanitize(object: content)
        do {
            let data = try JSONSerialization.data(withJSONObject: sanitizedContent, options: [])
            let result = try JSONDecoder().decode(NotionUpdateHeading2.self, from: data)
            return result
        } catch {
            return nil
        }
    }
    
    /// Recursively converts any JSONNull instances to NSNull so that JSONSerialization does not fail.
    private func sanitize(object: Any) -> Any {
        if object is JSONNull {
            return NSNull()
        } else if let array = object as? [Any] {
            return array.map { sanitize(object: $0) }
        } else if let dict = object as? [String: Any] {
            var sanitized = [String: Any]()
            for (key, value) in dict {
                sanitized[key] = sanitize(object: value)
            }
            return sanitized
        }
        return object
    }
}
