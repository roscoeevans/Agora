import Foundation
import Security

/// Protocol for keychain operations
public protocol KeychainHelperProtocol: Sendable {
    func storeSession(_ session: Session) async throws
    func loadSession() async throws -> Session?
    func deleteCredentials() async
}

/// Helper for secure storage of authentication credentials in Keychain
public actor KeychainHelper: KeychainHelperProtocol {
    
    public init() {}
    
    // MARK: - Constants
    
    private enum Keys {
        static let sessionData = "com.agora.auth.session"
        static let service = "com.agora.app"
    }
    
    // MARK: - Public Methods
    
    /// Stores authentication session in keychain
    public func storeSession(_ session: Session) async throws {
        let data = try JSONEncoder().encode(session)
        try await storeData(data, forKey: Keys.sessionData)
    }
    
    /// Loads authentication session from keychain
    public func loadSession() async throws -> Session? {
        guard let data = try await loadData(forKey: Keys.sessionData) else {
            return nil
        }
        
        return try JSONDecoder().decode(Session.self, from: data)
    }
    
    /// Deletes all stored credentials
    public func deleteCredentials() async {
        await deleteData(forKey: Keys.sessionData)
    }
    
    // MARK: - Private Methods
    
    private func storeData(_ data: Data, forKey key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        await deleteData(forKey: key)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    private func loadData(forKey key: String) async throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.loadFailed(status)
        }
    }
    
    private func deleteData(forKey key: String) async {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Keychain Errors

public enum KeychainError: LocalizedError, Sendable {
    case storeFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    public var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store data in keychain: \(status)"
        case .loadFailed(let status):
            return "Failed to load data from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete data from keychain: \(status)"
        }
    }
}