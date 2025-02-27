import Foundation

// MARK: - NotionPropertyItem

public struct NotionPropertyItem: Codable {
    public let object: String  // "property_item"
    public let id: String
    public let type: String

    // Depending on the property type, one of these may be present.
    public let number: Double?
    public let rich_text: [NotionRichText]?
    public let relation: JSONAny?
    public let rollup: JSONAny?
    public let people: JSONAny?
    public let title: [NotionRichText]?
    
    enum CodingKeys: String, CodingKey {
        case object, id, type, number, rich_text, relation, rollup, people, title
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        object = try container.decode(String.self, forKey: .object)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        number = try container.decodeIfPresent(Double.self, forKey: .number)
        rich_text = try container.decodeIfPresent([NotionRichText].self, forKey: .rich_text)
        relation = try container.decodeIfPresent(JSONAny.self, forKey: .relation)
        rollup = try container.decodeIfPresent(JSONAny.self, forKey: .rollup)
        people = try container.decodeIfPresent(JSONAny.self, forKey: .people)
        title = try container.decodeIfPresent([NotionRichText].self, forKey: .title)
    }
}

// MARK: - NotionPropertyItemList

public struct NotionPropertyItemList: Codable {
    public let object: String  // "list"
    public let results: [NotionPropertyItem]
    public let next_cursor: String?
    public let has_more: Bool
    // For rollup properties, an additional property_item may be provided.
    public let property_item: NotionPropertyItem?
    
    enum CodingKeys: String, CodingKey {
        case object, results, next_cursor, has_more, property_item
    }
}

// MARK: - NotionPropertyItemResponse

public enum NotionPropertyItemResponse: Codable {
    case single(NotionPropertyItem)
    case list(NotionPropertyItemList)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let objectType = try container.decode(String.self, forKey: .object)
        if objectType == "list" {
            let list = try NotionPropertyItemList(from: decoder)
            self = .list(list)
        } else {
            let item = try NotionPropertyItem(from: decoder)
            self = .single(item)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .single(let item):
            try item.encode(to: encoder)
        case .list(let list):
            try list.encode(to: encoder)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case object
    }
}
