import Foundation

struct NotionToken: Codable, Identifiable {
    let id = UUID()  // Unique identifier for the token
    var name: String
    var apiKey: String
}

class UserDefaultsManager {
    static let shared = UserDefaultsManager()

    private let notionTokensKey = "notion_api_tokens"

    /// Save a new Notion API Token
    func saveToken(name: String, apiKey: String) {
        var tokens = getTokens()
        tokens.append(NotionToken(name: name, apiKey: apiKey))
        save(tokens)
    }

    /// Retrieve all stored Notion API Tokens
    func getTokens() -> [NotionToken] {
        guard let data = UserDefaults.standard.data(forKey: notionTokensKey),
              let tokens = try? JSONDecoder().decode([NotionToken].self, from: data) else {
            return []
        }
        return tokens
    }

    /// Update an existing token’s API key
    func updateToken(id: UUID, newApiKey: String) {
        var tokens = getTokens()
        if let index = tokens.firstIndex(where: { $0.id == id }) {
            tokens[index].apiKey = newApiKey
            save(tokens)
        }
    }

    /// Delete a token
    func deleteToken(id: UUID) {
        var tokens = getTokens().filter { $0.id != id }
        save(tokens)
    }

    /// Save tokens to UserDefaults
    private func save(_ tokens: [NotionToken]) {
        if let data = try? JSONEncoder().encode(tokens) {
            UserDefaults.standard.set(data, forKey: notionTokensKey)
        }
    }
}
