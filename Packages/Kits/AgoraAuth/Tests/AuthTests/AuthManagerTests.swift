import XCTest
@testable import Auth
import AppFoundation
import AuthenticationServices

@available(iOS 26.0, macOS 10.15, *)
final class AuthManagerTests: XCTestCase {
    
    var authManager: AuthManager!
    var mockPhoneVerifier: MockPhoneVerifier!
    
    override func setUp() async throws {
        mockPhoneVerifier = MockPhoneVerifier()
        authManager = AuthManager(phoneVerifier: mockPhoneVerifier)
    }
    
    override func tearDown() async throws {
        authManager = nil
        mockPhoneVerifier = nil
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() async {
        let isAuthenticated = await authManager.isAuthenticated
        XCTAssertFalse(isAuthenticated)
        
        let token = try? await authManager.currentAccessToken()
        XCTAssertNil(token)
    }
    
    // MARK: - Token Provider Tests
    
    func testCurrentAccessTokenWhenUnauthenticated() async throws {
        let token = try await authManager.currentAccessToken()
        XCTAssertNil(token)
    }
    
    // MARK: - Phone Verification Tests
    
    func testPhoneVerificationRequiresAuthentication() async {
        do {
            _ = try await authManager.startPhoneVerification(phoneNumber: "+1234567890")
            XCTFail("Should have thrown authentication error")
        } catch AuthError.notAuthenticated {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testVerifyPhoneCodeWithoutSession() async {
        do {
            _ = try await authManager.verifyPhoneCode("123456")
            XCTFail("Should have thrown session expired error")
        } catch PhoneVerificationError.sessionExpired {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Mock Phone Verifier Tests
    
    func testMockPhoneVerifierSuccess() async throws {
        await mockPhoneVerifier.setShouldSucceed(true)
        
        let sessionId = try await mockPhoneVerifier.sendVerificationCode(to: "+1234567890")
        XCTAssertFalse(sessionId.isEmpty)
        
        let isValid = try await mockPhoneVerifier.verifyCode("123456", sessionId: sessionId)
        XCTAssertTrue(isValid)
    }
    
    func testMockPhoneVerifierFailure() async throws {
        await mockPhoneVerifier.setShouldSucceed(false)
        
        do {
            _ = try await mockPhoneVerifier.sendVerificationCode(to: "+1234567890")
            XCTFail("Should have thrown error")
        } catch PhoneVerificationError.sendFailed {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testMockPhoneVerifierInvalidCode() async throws {
        await mockPhoneVerifier.setShouldSucceed(true)
        
        let sessionId = try await mockPhoneVerifier.sendVerificationCode(to: "+1234567890")
        
        // Test with invalid code
        let isValid = try await mockPhoneVerifier.verifyCode("000000", sessionId: sessionId)
        XCTAssertFalse(isValid)
    }
    
    func testMockPhoneVerifierWithDelay() async throws {
        await mockPhoneVerifier.setVerificationDelay(0.1) // 100ms delay
        await mockPhoneVerifier.setShouldSucceed(true)
        
        let startTime = Date()
        _ = try await mockPhoneVerifier.sendVerificationCode(to: "+1234567890")
        let endTime = Date()
        
        let elapsed = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(elapsed, 0.1)
    }
    
    func testMockPhoneVerifierCodeValidation() async throws {
        await mockPhoneVerifier.setShouldSucceed(true)
        
        let sessionId = try await mockPhoneVerifier.sendVerificationCode(to: "+1234567890")
        
        // Test various codes
        let testCases = [
            ("123456", true),   // Valid code
            ("000000", false),  // Invalid code
            ("111111", false),  // Invalid code
            ("654321", false),  // Invalid code
            ("", false),        // Empty code
            ("12345", false),   // Too short
            ("1234567", false), // Too long
        ]
        
        for (code, expectedResult) in testCases {
            let result = try await mockPhoneVerifier.verifyCode(code, sessionId: sessionId)
            XCTAssertEqual(result, expectedResult, "Code '\(code)' should return \(expectedResult)")
        }
    }
    
    func testMockPhoneVerifierStatusCheck() async throws {
        await mockPhoneVerifier.setShouldSucceed(true)
        
        let status = try await mockPhoneVerifier.getVerificationStatus(sessionId: "test_session")
        XCTAssertEqual(status, .pending)
    }
    
    func testMockPhoneVerifierStatusCheckFailure() async throws {
        await mockPhoneVerifier.setShouldSucceed(false)
        
        do {
            _ = try await mockPhoneVerifier.getVerificationStatus(sessionId: "test_session")
            XCTFail("Should have thrown statusCheckFailed error")
        } catch PhoneVerificationError.statusCheckFailed(let code) {
            XCTAssertEqual(code, 400)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Helper Extensions

extension MockPhoneVerifier {
    func setShouldSucceed(_ value: Bool) async {
        shouldSucceed = value
    }
    
    func setVerificationDelay(_ value: TimeInterval) async {
        verificationDelay = value
    }
}