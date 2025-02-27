import Foundation

/// Request model for creating a new comment.
public struct NotionCreateCommentRequest: Codable {
    /// A parent object with a page_id is required if creating a new comment on a page.
    public let parent: NotionCreateCommentParent?
    /// A discussion_id is required if adding a comment to an existing discussion thread.
    public let discussionID: String?
    /// A rich text array representing the comment content.
    public let richText: [NotionRichText]
    
    enum CodingKeys: String, CodingKey {
        case parent
        case discussionID = "discussion_id"
        case richText = "rich_text"
    }
    
    public init(parent: NotionCreateCommentParent? = nil,
                discussionID: String? = nil,
                richText: [NotionRichText]) {
        self.parent = parent
        self.discussionID = discussionID
        self.richText = richText
    }
}

/// A parent object for a comment when creating a comment on a page.
public struct NotionCreateCommentParent: Codable {
    public let type: String
    public let pageID: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case pageID = "page_id"
    }
    
    public init(pageID: String) {
        self.type = "page_id"
        self.pageID = pageID
    }
}
