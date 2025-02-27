import Foundation

public struct NotionBlockChildrenResponse: Codable {
    public let object: String
    public let results: [NotionBlock]
    public let nextCursor: String?
    public let hasMore: Bool
    public let type: String
    public let block: JSONAny?
    
    enum CodingKeys: String, CodingKey {
        case object, results, type, block
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}
