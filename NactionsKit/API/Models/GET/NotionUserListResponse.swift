import Foundation

public struct NotionUserListResponse: Codable {
    public let object: String
    public let results: [NotionUser]
    public let nextCursor: String?
    public let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case object, results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}
