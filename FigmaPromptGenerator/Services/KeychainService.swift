import Foundation
import Security

enum KeychainService {
    private static let service = "com.guilherme.FigmaPromptGenerator"
    private static let account = "openAIAPIKey"

    static func readAPIKey() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else { return "" }
        return key
    }

    static func saveAPIKey(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes = [kSecValueData as String: Data(key.utf8)]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = Data(key.utf8)
            guard SecItemAdd(newItem as CFDictionary, nil) == errSecSuccess else {
                throw KeychainError.saveFailed
            }
        } else if status != errSecSuccess {
            throw KeychainError.saveFailed
        }
    }

    enum KeychainError: LocalizedError {
        case saveFailed
        var errorDescription: String? { "Unable to save the API key to Keychain." }
    }
}
