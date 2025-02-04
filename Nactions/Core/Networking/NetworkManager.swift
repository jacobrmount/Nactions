import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    func sendRequest(url: String, method: String = "GET") async -> (Data?, URLResponse?) {
        guard let url = URL(string: url) else { return (nil, nil) }
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            return (data, response)
        } catch {
            return (nil, nil)
        }
    }
}
