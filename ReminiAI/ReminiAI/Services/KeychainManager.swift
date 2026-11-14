import Foundation
import Security

/// Secure Keychain storage for sensitive credentials such as Replicate API Tokens
final class KeychainManager {
    static let shared = KeychainManager()
    
    private let serviceIdentifier = "com.saiganesh.reminiai"
    private let replicateAccountKey = "replicate_api_token"
    
    private init() {}
    
    /// Save or update an API token in the Keychain
    @discardableResult
    func saveReplicateToken(_ token: String) -> Bool {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else {
            return deleteReplicateToken()
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: replicateAccountKey
        ]
        
        // Remove any prior entry before adding
        SecItemDelete(query as CFDictionary)
        
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: replicateAccountKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve the stored token from Keychain
    func getReplicateToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: replicateAccountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data, let token = String(data: data, encoding: .utf8) {
            return token
        }
        return nil
    }
    
    /// Remove stored token from Keychain
    @discardableResult
    func deleteReplicateToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: replicateAccountKey
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
