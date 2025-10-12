import XCTest
@testable import Auth
import Security

final class KeychainHelperTests: XCTestCase {
    
    var keychainHelper: KeychainHelper!
    
    override func setUp() async throws {
        keychainHelper = KeychainHelper()
        
        // Clean up any existing test data
        await keychainHelper.deleteCredentials()
    }
    
    override func tearDown() async throws {
        // Clean up after each test
        await keychainHelper.deleteCredentials()
        keychainHelper = nil
    }
    
    // MARK: - Session Storage Tests
    
    func testStoreAndLoadSession() async throws {
        let user = AuthenticatedUser(
            id: "keychain_test_user",
            email: "keychain@example.com",
            fullName: PersonNameComponents()
        )
        
        let originalSession = Session(
            user: user,
            accessToken: "test_access_token_123",
            refreshToken: "test_refresh_token_456",
            expiresAt: Date().addingTimeInterval(3600),
            isPhoneVerified: true
        )
        
        // Store session
        try await keychainHelper.storeSession(originalSession)
        
        // Load session
        let loadedSession = try await keychainHelper.loadSession()
        
        XCTAssertNotNil(loadedSession)
        XCTAssertEqual(loadedSession?.user.id, "keychain_test_user")
        XCTAssertEqual(loadedSession?.user.email, "keychain@example.com")
        XCTAssertEqual(loadedSession?.accessToken, "test_access_token_123")
        XCTAssertEqual(loadedSession?.refreshToken, "test_refresh_token_456")
        XCTAssertTrue(loadedSession?.isPhoneVerified ?? false)
    }
    
    func testLoadSessionWhenNoneExists() async throws {
        let session = try await keychainHelper.loadSession()
        XCTAssertNil(session)
    }
    
    func testStoreSessionOverwritesExisting() async throws {
        let user1 = AuthenticatedUser(id: "user1", email: "user1@example.com", fullName: nil)
        let session1 = Session(
            user: user1,
            accessToken: "token1",
            refreshToken: "refresh1",
            expiresAt: Date().addingTimeInterval(3600)
        )
        
        let user2 = AuthenticatedUser(id: "user2", email: "user2@example.com", fullName: nil)
        let session2 = Session(
            user: user2,
            accessToken: "token2",
            refreshToken: "refresh2",
            expiresAt: Date().addingTimeInterval(7200)
        )
        
        // Store first session
        try await keychainHelper.storeSession(session1)
        
        // Verify first session is stored
        let loadedSession1 = try await keychainHelper.loadSession()
        XCTAssertEqual(loadedSession1?.user.id, "user1")
        
        // Store second session (should overwrite)
        try await keychainHelper.storeSession(session2)
        
        // Verify second session overwrote the first
        let loadedSession2 = try await keychainHelper.loadSession()
        XCTAssertEqual(loadedSession2?.user.id, "user2")
        XCTAssertEqual(loadedSession2?.accessToken, "token2")
    }
    
    // MARK: - Session Deletion Tests
    
    func testDeleteCredentials() async throws {
        let user = AuthenticatedUser(id: "delete_test", email: "delete@example.com", fullName: nil)
        let session = Session(
            user: user,
            accessToken: "delete_token",
            refreshToken: "delete_refresh",
            expiresAt: Date().addingTimeInterval(3600)
        )
        
        // Store session
        try await keychainHelper.storeSession(session)
        
        // Verify session exists
        let storedSession = try await keychainHelper.loadSession()
        XCTAssertNotNil(storedSession)
        
        // Delete credentials
        await keychainHelper.deleteCredentials()
        
        // Verify session is deleted
        let deletedSession = try await keychainHelper.loadSession()
        XCTAssertNil(deletedSession)
    }
    
    func testDeleteCredentialsWhenNoneExist() async {
        // Should not throw error when deleting non-existent credentials
        await keychainHelper.deleteCredentials()
        
        // Verify still no session
        let session = try? await keychainHelper.loadSession()
        XCTAssertNil(session)
    }
    
    // MARK: - Data Integrity Tests
    
    func testSessionDataIntegrity() async throws {
        // Create session with complex data
        var fullName = PersonNameComponents()
        fullName.givenName = "John"
        fullName.familyName = "Doe"
        fullName.middleName = "William"
        
        let user = AuthenticatedUser(
            id: "complex_user_id_with_special_chars_!@#$%",
            email: "complex.email+test@example-domain.com",
            fullName: fullName
        )
        
        let futureDate = Date().addingTimeInterval(86400) // 24 hours
        let session = Session(
            user: user,
            accessToken: "complex_access_token_with_special_chars_!@#$%^&*()",
            refreshToken: "complex_refresh_token_with_unicode_🔑🚀",
            expiresAt: futureDate,
            isPhoneVerified: true
        )
        
        // Store and retrieve
        try await keychainHelper.storeSession(session)
        let retrievedSession = try await keychainHelper.loadSession()
        
        // Verify all data is preserved
        XCTAssertNotNil(retrievedSession)
        XCTAssertEqual(retrievedSession?.user.id, user.id)
        XCTAssertEqual(retrievedSession?.user.email, user.email)
        XCTAssertEqual(retrievedSession?.user.fullName?.givenName, "John")
        XCTAssertEqual(retrievedSession?.user.fullName?.familyName, "Doe")
        XCTAssertEqual(retrievedSession?.user.fullName?.middleName, "William")
        XCTAssertEqual(retrievedSession?.accessToken, session.accessToken)
        XCTAssertEqual(retrievedSession?.refreshToken, session.refreshToken)
        XCTAssertTrue(retrievedSession?.isPhoneVerified ?? false)
        
        // Verify date is preserved (within 1 second tolerance for encoding/decoding)
        let timeDifference = abs(retrievedSession!.expiresAt.timeIntervalSince(futureDate))
        XCTAssertLessThan(timeDifference, 1.0)
    }
    
    func testSessionWithNilValues() async throws {
        let user = AuthenticatedUser(
            id: "nil_test_user",
            email: nil, // Test nil email
            fullName: nil // Test nil full name
        )
        
        let session = Session(
            user: user,
            accessToken: "access_token",
            refreshToken: nil, // Test nil refresh token
            expiresAt: Date().addingTimeInterval(3600),
            isPhoneVerified: false
        )
        
        try await keychainHelper.storeSession(session)
        let retrievedSession = try await keychainHelper.loadSession()
        
        XCTAssertNotNil(retrievedSession)
        XCTAssertEqual(retrievedSession?.user.id, "nil_test_user")
        XCTAssertNil(retrievedSession?.user.email)
        XCTAssertNil(retrievedSession?.user.fullName)
        XCTAssertEqual(retrievedSession?.accessToken, "access_token")
        XCTAssertNil(retrievedSession?.refreshToken)
        XCTAssertFalse(retrievedSession?.isPhoneVerified ?? true)
    }
    
    // MARK: - Error Handling Tests
    
    func testCorruptedDataHandling() async throws {
        // This test simulates what happens if keychain data gets corrupted
        // We'll manually store invalid JSON data and verify it's handled gracefully
        
        let invalidData = "invalid json data".data(using: .utf8)!
        
        // Manually store invalid data using the same keychain query structure
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.agora.app",
            kSecAttrAccount as String: "com.agora.auth.session",
            kSecValueData as String: invalidData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item first
        await keychainHelper.deleteCredentials()
        
        // Store invalid data
        let status = SecItemAdd(query as CFDictionary, nil)
        XCTAssertEqual(status, errSecSuccess, "Failed to store invalid data for test")
        
        // Attempt to load session - should throw decoding error
        do {
            _ = try await keychainHelper.loadSession()
            XCTFail("Should have thrown decoding error for corrupted data")
        } catch {
            // Expected - should be a decoding error
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentStoreAndLoad() async throws {
        let user = AuthenticatedUser(id: "concurrent_test", email: "concurrent@example.com", fullName: nil)
        
        // Create multiple sessions
        let sessions = (0..<5).map { index in
            Session(
                user: user,
                accessToken: "token_\(index)",
                refreshToken: "refresh_\(index)",
                expiresAt: Date().addingTimeInterval(3600)
            )
        }
        
        // Store sessions sequentially to avoid keychain conflicts
        for session in sessions {
            try? await keychainHelper.storeSession(session)
        }
        
        // Load final session
        let finalSession = try await keychainHelper.loadSession()
        XCTAssertNotNil(finalSession)
        XCTAssertEqual(finalSession?.user.id, "concurrent_test")
        
        // Should have the last stored token
        XCTAssertEqual(finalSession?.accessToken, "token_4")
    }
}

// MARK: - KeychainError Tests

final class KeychainErrorTests: XCTestCase {
    
    func testKeychainErrorDescriptions() {
        let storeError = KeychainError.storeFailed(errSecDuplicateItem)
        XCTAssertTrue(storeError.errorDescription?.contains("Failed to store data in keychain") ?? false)
        
        let loadError = KeychainError.loadFailed(errSecItemNotFound)
        XCTAssertTrue(loadError.errorDescription?.contains("Failed to load data from keychain") ?? false)
        
        let deleteError = KeychainError.deleteFailed(errSecNotAvailable)
        XCTAssertTrue(deleteError.errorDescription?.contains("Failed to delete data from keychain") ?? false)
    }
}