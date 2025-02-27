import Foundation

/// Request model for appending new children blocks to a parent block.
public struct NotionAppendBlockChildrenRequest: Codable {
    /// An array of new block objects to append.
    public let children: [NotionBlock]
    /// Optional: The ID of the block after which the new blocks should be appended.
    public let after: String?
    
    public init(children: [NotionBlock], after: String? = nil) {
        self.children = children
        self.after = after
    }
}
