import XCTest
@testable import Auth
import Foundation

final class PhoneVerifierTests: XCTestCase {
    
    // MARK: - MockPhoneVerifier Tests
    
    func testMockPhoneVerifierSuccessFlow() async throws {
        let mockVerifier = MockPhoneVerifier()
        await mockVerifier.setShouldSucceed(true)
        
        // Test sending verification code
        let sessionId = try await mockVerifier.sendVerificationCode(to: "+1234567890")
        XCTAssertFalse(sessionId.isEmpty)
        XCTAssertTrue(sessionId.hasPrefix("mock_session_"))
        
        // Test verifying correct code
        let isValidCorrect = try await mockVerifier.verifyCode("123456", sessionId: sessionId)
        XCTAssertTrue(isValidCorrect)
        
        // Test verifying incorrect code
        let isValidIncorrect = try await mockVerifier.verifyCode("000000", sessionId: sessionId)
        XCTAssertFalse(isValidIncorrect)
        
        // Test status check
        let status = try await mockVerifier.getVerificationStatus(sessionId: sessionId)
        XCTAssertEqual(status, .pending)
    }
    
    func testMockPhoneVerifierFailureFlow() async throws {
        let mockVerifier = MockPhoneVerifier()
        await mockVerifier.setShouldSucceed(false)
        
        // Test sending verification code fails
        do {
            _ = try await mockVerifier.sendVerificationCode(to: "+1234567890")
            XCTFail("Should have thrown sendFailed error")
        } catch PhoneVerificationError.sendFailed(let code) {
            XCTAssertEqual(code, 400)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test verifying code fails
        do {
            _ = try await mockVerifier.verifyCode("123456", sessionId: "test_session")
            XCTFail("Should have thrown verificationFailed error")
        } catch PhoneVerificationError.verificationFailed(let code) {
            XCTAssertEqual(code, 400)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test status check fails
        do {
            _ = try await mockVerifier.getVerificationStatus(sessionId: "test_session")
            XCTFail("Should have thrown statusCheckFailed error")
        } catch PhoneVerificationError.statusCheckFailed(let code) {
            XCTAssertEqual(code, 400)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testMockPhoneVerifierWithDelay() async throws {
        let mockVerifier = MockPhoneVerifier()
        await mockVerifier.setShouldSucceed(true)
        await mockVerifier.setVerificationDelay(0.1) // 100ms delay
        
        let startTime = Date()
        _ = try await mockVerifier.sendVerificationCode(to: "+1234567890")
        let endTime = Date()
        
        let elapsed = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(elapsed, 0.1)
    }
    
    func testMockPhoneVerifierCodeValidation() async throws {
        let mockVerifier = MockPhoneVerifier()
        await mockVerifier.setShouldSucceed(true)
        
        let sessionId = try await mockVerifier.sendVerificationCode(to: "+1234567890")
        
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
            let result = try await mockVerifier.verifyCode(code, sessionId: sessionId)
            XCTAssertEqual(result, expectedResult, "Code '\(code)' should return \(expectedResult)")
        }
    }
    
    // MARK: - TwilioPhoneVerifier Tests (Mock Network)
    // Note: These tests would require creating a testable TwilioPhoneVerifier
    // that accepts a protocol-based URLSession. For now, we focus on testing
    // the MockPhoneVerifier which is what's actually used in the app.
}

// MARK: - VerificationStatus Tests

final class VerificationStatusTests: XCTestCase {
    
    func testVerificationStatusRawValues() {
        XCTAssertEqual(VerificationStatus.pending.rawValue, "pending")
        XCTAssertEqual(VerificationStatus.approved.rawValue, "approved")
        XCTAssertEqual(VerificationStatus.canceled.rawValue, "canceled")
        XCTAssertEqual(VerificationStatus.expired.rawValue, "expired")
    }
    
    func testVerificationStatusFromRawValue() {
        XCTAssertEqual(VerificationStatus(rawValue: "pending"), .pending)
        XCTAssertEqual(VerificationStatus(rawValue: "approved"), .approved)
        XCTAssertEqual(VerificationStatus(rawValue: "canceled"), .canceled)
        XCTAssertEqual(VerificationStatus(rawValue: "expired"), .expired)
        XCTAssertNil(VerificationStatus(rawValue: "invalid"))
    }
    
    func testVerificationStatusCaseIterable() {
        let allCases = VerificationStatus.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.pending))
        XCTAssertTrue(allCases.contains(.approved))
        XCTAssertTrue(allCases.contains(.canceled))
        XCTAssertTrue(allCases.contains(.expired))
    }
}

// MARK: - PhoneVerificationError Tests

final class PhoneVerificationErrorTests: XCTestCase {
    
    func testPhoneVerificationErrorDescriptions() {
        let invalidPhoneError = PhoneVerificationError.invalidPhoneNumber
        XCTAssertEqual(invalidPhoneError.errorDescription, "Invalid phone number format")
        
        let sendFailedError = PhoneVerificationError.sendFailed(400)
        XCTAssertEqual(sendFailedError.errorDescription, "Failed to send verification code (HTTP 400)")
        
        let verificationFailedError = PhoneVerificationError.verificationFailed(401)
        XCTAssertEqual(verificationFailedError.errorDescription, "Verification failed (HTTP 401)")
        
        let statusCheckFailedError = PhoneVerificationError.statusCheckFailed(500)
        XCTAssertEqual(statusCheckFailedError.errorDescription, "Status check failed (HTTP 500)")
        
        let networkError = PhoneVerificationError.networkError
        XCTAssertEqual(networkError.errorDescription, "Network error occurred")
        
        let invalidCodeError = PhoneVerificationError.invalidCode
        XCTAssertEqual(invalidCodeError.errorDescription, "Invalid verification code")
        
        let sessionExpiredError = PhoneVerificationError.sessionExpired
        XCTAssertEqual(sessionExpiredError.errorDescription, "Verification session has expired")
    }
}



