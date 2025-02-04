import Foundation

class NotionIntegration {
    static let shared = NotionIntegration()
    
    func connectAPI(token: String) {
        KeychainHelper.shared.save(token, for: "notion_api_token")
    }
}
