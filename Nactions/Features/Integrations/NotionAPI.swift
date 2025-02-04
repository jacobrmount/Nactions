import Foundation

class NotionAPI {
    static let shared = NotionAPI()
    private let baseURL = "https://api.notion.com/v1/"

    /// Verifies if the Notion API Token is valid by calling `/users/me`
    func verifyToken(_ token: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)users/me") else {
            print("❌ Invalid URL")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2022-06-28", forHTTPHeaderField: "Notion-Version")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 400

            print("🔍 Response Code: \(statusCode)")
            return statusCode == 200  // ✅ Now returns `true` if valid, `false` otherwise.
        } catch {
            print("❌ Network Error: \(error.localizedDescription)")
            return false
        }
    }

    /// Create a new Notion page in a specified parent page or database
    func createPage(title: String, parentID: String) async -> Bool {
        let url = URL(string: "\(baseURL)pages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(getToken())", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "parent": ["page_id": parentID], // Specify where to create the page
            "properties": [
                "title": [
                    ["text": ["content": title]] // Page title
                ]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 400
            
            if statusCode == 200 {
                print("✅ Page Created Successfully: \(String(data: data, encoding: .utf8) ?? "")")
                return true
            } else {
                print("❌ Failed to Create Page. Status Code: \(statusCode)")
                return false
            }
        } catch {
            print("❌ Error creating Notion page: \(error.localizedDescription)")
            return false
        }
    }

    /// Retrieve the stored Notion API token
    private func getToken() -> String {
        return UserDefaultsManager.shared.getTokens().first?.apiKey ?? ""
    }
}
