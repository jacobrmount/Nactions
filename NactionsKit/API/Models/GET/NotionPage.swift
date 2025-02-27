import Foundation

// MARK: - NotionPage
public struct NotionPage: Codable {
    public let object: String
    public let id: String
    public let createdTime: Date?
    public let lastEditedTime: Date?
    public let createdBy: NotionUser?
    public let lastEditedBy: NotionUser?
    public let cover: NotionCover?
    public let icon: NotionIcon?
    public let parent: NotionParent?
    public let archived: Bool?
    public let properties: [String: JSONAny]?
    public let url: String?
    
    enum CodingKeys: String, CodingKey {
        case object, id, cover, icon, parent, archived, properties, url
        case createdTime = "created_time"
        case lastEditedTime = "last_edited_time"
        case createdBy = "created_by"
        case lastEditedBy = "last_edited_by"
    }
}

// MARK: - NotionUser
public struct NotionUser: Codable {
    public let object: String
    public let id: String
    public let type: String?
    public let person: NotionPerson?
    public let name: String?
    public let avatarURL: String?
    public let bot: NotionBot?
    
    enum CodingKeys: String, CodingKey {
        case object, id, type, person, name, bot
        case avatarURL = "avatar_url"
    }
}

public struct NotionPerson: Codable {
    public let email: String?
}

// MARK: - NotionBot and Owner
public struct NotionBot: Codable {
    public let owner: NotionBotOwner?
    /// Top-level "workspace_name" for some tokens
    public let workspaceName: String?
    
    enum CodingKeys: String, CodingKey {
        case owner
        case workspaceName = "workspace_name"
    }
    
    // Custom init to handle "workspace_name" at either top-level or inside owner
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode the entire owner object (which might have workspace_name for some tokens)
        self.owner = try container.decodeIfPresent(NotionBotOwner.self, forKey: .owner)
        
        // Some tokens put "workspace_name" directly at top-level in "bot"
        let topLevelName = try container.decodeIfPresent(String.self, forKey: .workspaceName)
        
        // If top-level name is nil, fallback to owner?.workspaceName
        self.workspaceName = topLevelName ?? owner?.workspaceName
    }
    
    // Default memberwise init if you need it
    public init(owner: NotionBotOwner?, workspaceName: String?) {
        self.owner = owner
        self.workspaceName = workspaceName
    }
}

public struct NotionBotOwner: Codable {
    /// "workspace" or "user"
    public let type: String?
    /// Present when `type == "workspace"`.
    public let workspace: Bool?
    /// Some tokens nest "workspace_name" here.
    public let workspaceName: String?
    /// Present when `type == "user"`.
    public let user: NotionBotOwnerUser?
    
    enum CodingKeys: String, CodingKey {
        case type
        case workspace
        case workspaceName = "workspace_name"
        case user
    }
}

// MARK: - NotionBotOwnerUser
public struct NotionBotOwnerUser: Codable {
    public let object: String?
    public let id: String?
    public let name: String?
    public let avatarURL: String?
    public let type: String?
    public let person: NotionPerson?
    
    enum CodingKeys: String, CodingKey {
        case object, id, name, type, person
        case avatarURL = "avatar_url"
    }
}

// MARK: - NotionCover
public struct NotionCover: Codable {
    public let type: String
    public let external: NotionExternalFile?
}

// MARK: - NotionExternalFile
public struct NotionExternalFile: Codable {
    public let url: String
}

// MARK: - NotionIcon
public struct NotionIcon: Codable {
    public let type: String
    public let emoji: String?
}

// MARK: - NotionParent
public struct NotionParent: Codable {
    public let type: String
    public let databaseID: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case databaseID = "database_id"
    }
}

// MARK: - JSONAny and helpers
public class JSONNull: Codable, Hashable {
    public init() {}
    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool { return true }
    public func hash(into hasher: inout Hasher) { hasher.combine(0) }
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Wrong type for JSONNull"))
        }
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

public struct JSONCodingKey: CodingKey {
    public var stringValue: String
    public init?(stringValue: String) { self.stringValue = stringValue }
    public var intValue: Int?
    public init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

public class JSONAny: Codable {
    public let value: Any
    
    public static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Cannot decode JSONAny"
        )
        return DecodingError.typeMismatch(JSONAny.self, context)
    }
    
    public static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(
            codingPath: codingPath,
            debugDescription: "Cannot encode JSONAny"
        )
        return EncodingError.invalidValue(value, context)
    }
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = JSONNull()
        } else if let boolVal = try? container.decode(Bool.self) {
            self.value = boolVal
        } else if let intVal = try? container.decode(Int.self) {
            self.value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            self.value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            self.value = stringVal
        } else if var arrayContainer = try? decoder.unkeyedContainer() {
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var dictContainer = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &dictContainer)
        } else {
            throw JSONAny.decodingError(forCodingPath: decoder.codingPath)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self.value {
        case is JSONNull:
            try container.encodeNil()
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let arrayVal as [Any]:
            var arrayContainer = encoder.unkeyedContainer()
            try JSONAny.encode(to: &arrayContainer, array: arrayVal)
        case let dictVal as [String: Any]:
            var dictContainer = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &dictContainer, dictionary: dictVal)
        default:
            throw JSONAny.encodingError(forValue: self.value, codingPath: encoder.codingPath)
        }
    }
    
    private static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try container.decode(JSONAny.self)
            arr.append(value.value)
        }
        return arr
    }
    
    private static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try container.decode(JSONAny.self, forKey: key)
            dict[key.stringValue] = value.value
        }
        return dict
    }
    
    private static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
        for value in array {
            let jsonAny = JSONAny(value)
            try container.encode(jsonAny)
        }
    }
    
    private static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            let keyCoding = JSONCodingKey(stringValue: key)!
            let jsonAny = JSONAny(value)
            try container.encode(jsonAny, forKey: keyCoding)
        }
    }
}
