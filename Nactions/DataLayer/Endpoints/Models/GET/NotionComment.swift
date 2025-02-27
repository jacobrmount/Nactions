import Foundation

public struct NotionCommentParent: Codable {
    public let type: String
    public let pageID: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case pageID = "page_id"
    }
}

public struct NotionComment: Codable {
    public let object: String
    public let id: String
    public let parent: NotionCommentParent
    public let discussionID: String
    public let createdTime: Date
    public let lastEditedTime: Date
    public let createdBy: NotionUser
    public let richText: [NotionRichText]
    
    enum CodingKeys: String, CodingKey {
        case object, id, parent
        case discussionID = "discussion_id"
        case createdTime = "created_time"
        case lastEditedTime = "last_edited_time"
        case createdBy = "created_by"
        case richText = "rich_text"
    }
}

public struct NotionCommentListResponse: Codable {
    public let object: String
    public let results: [NotionComment]
    public let nextCursor: String?
    public let hasMore: Bool
    public let type: String
    public let comment: JSONAny?
    
    enum CodingKeys: String, CodingKey {
        case object, results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
        case type, comment
    }
}
