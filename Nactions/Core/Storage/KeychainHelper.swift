import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()

    /// Save a value in Keychain
    func save(_ value: String, for key: String) {
        let data = value.data(using: .utf8)!
        
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("🔴 Failed to save token in Keychain: \(status)")
        } else {
            print("✅ Token successfully saved in Keychain.")
        }
    }

    /// Retrieve a value from Keychain
    func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue as Any
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        } else {
            print("🔴 Failed to retrieve token: \(status)")
            return nil
        }
    }
}
