import Foundation

public struct NotionCreateTokenRequest: Codable {
    public let code: String
    public let grantType: String
    public let redirectURI: String?
    
    enum CodingKeys: String, CodingKey {
        case code
        case grantType = "grant_type"
        case redirectURI = "redirect_uri"
    }
    
    public init(code: String, grantType: String = "authorization_code", redirectURI: String? = nil) {
        self.code = code
        self.grantType = grantType
        self.redirectURI = redirectURI
    }
}

public struct NotionCreateTokenResponse: Codable {
    public let accessToken: String
    public let botID: String?
    public let duplicatedTemplateID: String?
    public let owner: NotionTokenOwner
    public let workspaceIcon: String?
    public let workspaceID: String
    public let workspaceName: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case botID = "bot_id"
        case duplicatedTemplateID = "duplicated_template_id"
        case owner
        case workspaceIcon = "workspace_icon"
        case workspaceID = "workspace_id"
        case workspaceName = "workspace_name"
    }
}

public struct NotionTokenOwner: Codable {
    public let workspace: Bool
}
