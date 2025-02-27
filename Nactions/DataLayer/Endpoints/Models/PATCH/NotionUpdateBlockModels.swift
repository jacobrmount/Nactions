import Foundation

/// Request model for updating a block.
/// Currently supports updating a heading_2 block.
/// Extend with additional fields for other block types as needed.
public struct NotionUpdateBlockRequest: Codable {
    /// For a heading_2 block, update its rich text content.
    public let heading2: NotionUpdateHeading2?
    
    enum CodingKeys: String, CodingKey {
        case heading2 = "heading_2"
    }
    
    public init(heading2: NotionUpdateHeading2? = nil) {
        self.heading2 = heading2
    }
}

/// Model for updating a heading_2 block.
public struct NotionUpdateHeading2: Codable {
    /// The new rich text content for the heading.
    public let richText: [NotionRichTextUpdate]
    
    enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
    }
    
    public init(richText: [NotionRichTextUpdate]) {
        self.richText = richText
    }
}

/// Model for updating a rich text object.
public struct NotionRichTextUpdate: Codable {
    public let text: NotionTextContent
    public let annotations: NotionAnnotations?
    
    public init(text: NotionTextContent, annotations: NotionAnnotations? = nil) {
        self.text = text
        self.annotations = annotations
    }
}

/// Model for the text content.
public struct NotionTextContent: Codable {
    public let content: String
    public let link: String?
    
    public init(content: String, link: String? = nil) {
        self.content = content
        self.link = link
    }
}

/// Model for text annotations.
public struct NotionAnnotations: Codable {
    public let color: String
    
    public init(color: String) {
        self.color = color
    }
}
