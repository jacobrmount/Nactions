import Foundation

public struct NotionDatabase: Codable {
    public let object: String
    public let id: String
    public let createdTime: Date?
    public let lastEditedTime: Date?
    public let title: [NotionRichText]?
    public let description: [NotionRichText]?  // Newly added optional property for description
    public let url: String?

    enum CodingKeys: String, CodingKey {
        case object
        case id
        case createdTime = "created_time"
        case lastEditedTime = "last_edited_time"
        case title
        case description
        case url
    }
}

public struct NotionRichText: Codable {
    public let plainText: String?

    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
    }
}
