import Foundation
import Security

@MainActor
enum KeychainService {
    private static let service = "com.guilherme.FigmaPromptGenerator"
    private static let account = "openAIAPIKey"
    private static let cacheKey: NSString = "openAIAPIKey"
    private static let apiKeyCache = NSCache<NSString, NSString>()

    static func readAPIKey() -> String {
        if let cachedKey = apiKeyCache.object(forKey: cacheKey) {
            return cachedKey as String
        }
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
        apiKeyCache.setObject(key as NSString, forKey: cacheKey)
        return key
    }

    static func saveAPIKey(_ key: String) throws {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw KeychainError.emptyKey }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes = [kSecValueData as String: Data(trimmedKey.utf8)]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = Data(trimmedKey.utf8)
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.saveFailed(addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.saveFailed(status)
        }
        apiKeyCache.setObject(trimmedKey as NSString, forKey: cacheKey)
    }

    enum KeychainError: LocalizedError {
        case emptyKey
        case saveFailed(OSStatus)

        var errorDescription: String? {
            switch self {
            case .emptyKey:
                return "Enter an OpenAI API key before saving."
            case .saveFailed(let status):
                let description = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown Keychain error"
                return "Unable to save the API key to Keychain: \(description) (\(status))."
            }
        }
    }
}
