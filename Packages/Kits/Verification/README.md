# Verification Kit

The Verification kit provides device attestation and phone verification functionality for the Agora iOS app.

## Overview

This module handles:
- App Attest integration for device attestation
- Twilio Verify integration for phone verification
- DeviceCheck validation for posting eligibility
- Device integrity checks
- Anti-fraud measures

## Components

### AppAttestManager
Manages App Attest for device attestation.

```swift
let appAttest = AppAttestManager.shared

// Check if supported
if appAttest.isSupported {
    // Perform full attestation
    let result = try await appAttest.performAttestation(challenge: "server-challenge")
    
    // Generate authenticated assertion
    let assertion = try await appAttest.generateAuthenticatedAssertion(
        keyId: result.keyId,
        requestData: requestData
    )
}
```

### PhoneVerifier
Handles phone number verification via Twilio Verify.

```swift
let phoneVerifier = PhoneVerifier.shared

// Send verification code
try await phoneVerifier.sendVerificationCode(to: "+1234567890")

// Verify code
let result = try await phoneVerifier.verifyCode("123456")

if result.isVerified {
    print("Phone verified: \(result.phoneNumber)")
}

// Utility methods
let isValid = phoneVerifier.isValidPhoneNumber("+1234567890")
let formatted = phoneVerifier.formatPhoneNumber("1234567890") // "(123) 456-7890"
```

### DeviceChecker
Uses DeviceCheck for device validation.

```swift
let deviceChecker = DeviceChecker.shared

// Check if supported
if deviceChecker.isSupported {
    // Verify device
    let result = try await deviceChecker.verifyDevice()
    
    // Check posting eligibility
    let eligibility = try await deviceChecker.checkPostingEligibility()
    
    if eligibility.isEligible {
        // User can post
    } else {
        print("Posting denied: \(eligibility.reasons)")
    }
}
```

## Verification Flow

For posting content, Agora requires:

1. **Sign in with Apple** - User authentication
2. **Phone Verification** - Human verification
3. **App Attest** - Device attestation
4. **DeviceCheck** - Device integrity

```swift
// Complete verification flow
func verifyForPosting() async throws -> Bool {
    // 1. Check device support
    guard AppAttestManager.shared.isSupported && DeviceChecker.shared.isSupported else {
        throw VerificationError.deviceNotSupported
    }
    
    // 2. Verify phone (if not already done)
    if phoneVerifier.status != .verified {
        try await phoneVerifier.sendVerificationCode(to: userPhoneNumber)
        // User enters code...
        let phoneResult = try await phoneVerifier.verifyCode(userEnteredCode)
        guard phoneResult.isVerified else {
            throw VerificationError.phoneVerificationFailed
        }
    }
    
    // 3. Perform device attestation
    let attestResult = try await AppAttestManager.shared.performAttestation(
        challenge: serverChallenge
    )
    
    // 4. Check posting eligibility
    let eligibility = try await DeviceChecker.shared.checkPostingEligibility()
    
    return eligibility.isEligible
}
```

## Phone Number Validation

The kit provides comprehensive phone number validation:

```swift
let phoneVerifier = PhoneVerifier.shared

// Validation
phoneVerifier.isValidPhoneNumber("1234567890") // true
phoneVerifier.isValidPhoneNumber("123") // false

// Formatting
phoneVerifier.formatPhoneNumber("1234567890") // "(123) 456-7890"
phoneVerifier.formatPhoneNumber("+441234567890") // "44 123 456 7890"
```

## Security Features

### Jailbreak Detection
The DeviceChecker includes basic jailbreak detection:
- Checks for common jailbreak files
- Tests system directory write permissions
- Validates app integrity

### Rate Limiting
Built-in protection against abuse:
- Limits verification attempts
- Tracks device usage patterns
- Prevents automated attacks

### Privacy Protection
- Minimal data collection
- Secure token handling
- No personal information stored locally

## Dependencies

- DeviceCheck (iOS system framework)
- CryptoKit (for hashing)
- Networking (for API communication)
- Foundation

## Usage

Import the module in your Swift files:

```swift
import Verification
```

## Architecture

The Verification kit is designed to be:
- Security-first with multiple verification layers
- Privacy-conscious with minimal data collection
- Resilient with proper error handling
- Testable with dependency injection
- Compliant with Apple's guidelines

## Testing

Run tests using:

```bash
swift test --package-path Packages/Kits/Verification
```

## Configuration

### Environment Setup
Configure for different environments:

```swift
#if DEBUG
// Use test phone numbers and mock responses
#else
// Use production Twilio credentials
#endif
```

### Error Handling
The kit provides comprehensive error types:

- `AttestationError` - App Attest failures
- `PhoneVerificationError` - Phone verification issues
- `DeviceCheckError` - DeviceCheck problems

## Integration Notes

### Server Requirements
Your backend needs to:
- Validate App Attest attestations
- Verify DeviceCheck tokens
- Handle Twilio Verify webhooks
- Store verification states

### Apple Requirements
- Enable App Attest capability
- Configure DeviceCheck service
- Handle attestation on server side

### Twilio Setup
- Configure Twilio Verify service
- Set up phone number validation
- Handle verification callbacks