import XCTest
@testable import Verification

final class VerificationTests: XCTestCase {
    
    func testVerificationModuleExists() {
        let verification = Verification.shared
        XCTAssertNotNil(verification)
    }
    
    func testAppAttestManagerInitialization() {
        let appAttestManager = AppAttestManager.shared
        XCTAssertNotNil(appAttestManager)
    }
    
    func testPhoneVerifierInitialization() {
        let phoneVerifier = PhoneVerifier.shared
        XCTAssertNotNil(phoneVerifier)
        XCTAssertEqual(phoneVerifier.status, .notStarted)
        XCTAssertFalse(phoneVerifier.isLoading)
    }
    
    func testDeviceCheckerInitialization() {
        let deviceChecker = DeviceChecker.shared
        XCTAssertNotNil(deviceChecker)
    }
    
    func testPhoneNumberValidation() {
        let phoneVerifier = PhoneVerifier.shared
        
        // Valid phone numbers
        XCTAssertTrue(phoneVerifier.isValidPhoneNumber("1234567890"))
        XCTAssertTrue(phoneVerifier.isValidPhoneNumber("+1 (234) 567-8900"))
        XCTAssertTrue(phoneVerifier.isValidPhoneNumber("123-456-7890"))
        XCTAssertTrue(phoneVerifier.isValidPhoneNumber("+44 20 7946 0958"))
        
        // Invalid phone numbers
        XCTAssertFalse(phoneVerifier.isValidPhoneNumber("123"))
        XCTAssertFalse(phoneVerifier.isValidPhoneNumber("abc"))
        XCTAssertFalse(phoneVerifier.isValidPhoneNumber(""))
        XCTAssertFalse(phoneVerifier.isValidPhoneNumber("12345678901234567890")) // Too long
    }
    
    func testPhoneNumberFormatting() {
        let phoneVerifier = PhoneVerifier.shared
        
        // US number formatting
        XCTAssertEqual(phoneVerifier.formatPhoneNumber("1234567890"), "(123) 456-7890")
        XCTAssertEqual(phoneVerifier.formatPhoneNumber("123-456-7890"), "(123) 456-7890")
        
        // International number formatting
        let formatted = phoneVerifier.formatPhoneNumber("441234567890")
        XCTAssertTrue(formatted.contains(" ")) // Should have spaces
        
        // Already formatted number
        let alreadyFormatted = "(123) 456-7890"
        XCTAssertEqual(phoneVerifier.formatPhoneNumber(alreadyFormatted), alreadyFormatted)
    }
    
    func testPhoneVerificationResult() {
        let result = PhoneVerificationResult(
            isVerified: true,
            phoneNumber: "+1234567890",
            verificationId: "test-id"
        )
        
        XCTAssertTrue(result.isVerified)
        XCTAssertEqual(result.phoneNumber, "+1234567890")
        XCTAssertEqual(result.verificationId, "test-id")
        XCTAssertNotNil(result.timestamp)
    }
    
    func testAttestationClientData() throws {
        let clientData = AttestationClientData(
            challenge: "test-challenge",
            timestamp: Date(),
            bundleId: "com.example.app"
        )
        
        XCTAssertEqual(clientData.challenge, "test-challenge")
        XCTAssertEqual(clientData.bundleId, "com.example.app")
        
        // Test hashing
        let hash = try clientData.hash()
        XCTAssertFalse(hash.isEmpty)
        
        // Same data should produce same hash
        let hash2 = try clientData.hash()
        XCTAssertEqual(hash, hash2)
    }
    
    func testAttestationResult() {
        let clientData = AttestationClientData(
            challenge: "test",
            timestamp: Date(),
            bundleId: "com.test"
        )
        
        let result = AttestationResult(
            keyId: "test-key",
            attestationObject: Data("test".utf8),
            clientData: clientData
        )
        
        XCTAssertEqual(result.keyId, "test-key")
        XCTAssertEqual(result.attestationObject, Data("test".utf8))
        XCTAssertEqual(result.clientData.challenge, "test")
    }
    
    func testDeviceVerificationResult() {
        let result = DeviceVerificationResult(
            isVerified: true,
            token: Data("token".utf8),
            timestamp: Date()
        )
        
        XCTAssertTrue(result.isVerified)
        XCTAssertEqual(result.token, Data("token".utf8))
        XCTAssertNotNil(result.timestamp)
    }
    
    func testPostingEligibilityResult() {
        let result = PostingEligibilityResult(
            isEligible: false,
            deviceVerified: true,
            reasons: ["Rate limited"]
        )
        
        XCTAssertFalse(result.isEligible)
        XCTAssertTrue(result.deviceVerified)
        XCTAssertEqual(result.reasons, ["Rate limited"])
    }
    
    func testPhoneVerificationErrors() {
        let invalidNumberError = PhoneVerificationError.invalidPhoneNumber
        XCTAssertNotNil(invalidNumberError.errorDescription)
        
        let invalidCodeError = PhoneVerificationError.invalidCode
        XCTAssertNotNil(invalidCodeError.errorDescription)
        
        let expiredError = PhoneVerificationError.codeExpired
        XCTAssertNotNil(expiredError.errorDescription)
    }
    
    func testAttestationErrors() {
        let notSupportedError = AttestationError.notSupported
        XCTAssertNotNil(notSupportedError.errorDescription)
        
        let keyGenError = AttestationError.keyGenerationFailed
        XCTAssertNotNil(keyGenError.errorDescription)
    }
    
    func testDeviceCheckErrors() {
        let notSupportedError = DeviceCheckError.notSupported
        XCTAssertNotNil(notSupportedError.errorDescription)
        
        let verificationError = DeviceCheckError.verificationFailed
        XCTAssertNotNil(verificationError.errorDescription)
    }
}