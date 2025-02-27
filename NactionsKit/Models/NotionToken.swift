// BusinessLogic/NotionToken.swift
import Foundation

public struct NotionToken: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var apiToken: String
    public var isConnected: Bool
    public var isActivated: Bool  // New property for token activation state
    
    public init(id: UUID, name: String, apiToken: String, isConnected: Bool, isActivated: Bool = false) {
        self.id = id
        self.name = name
        self.apiToken = apiToken
        self.isConnected = isConnected
        self.isActivated = isActivated
    }
}
