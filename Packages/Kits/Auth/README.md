# Auth Module

The Auth module provides comprehensive authentication and session management functionality for the Agora iOS app.

## Features

- **Sign in with Apple Integration**: Complete implementation of Apple's authentication flow
- **Secure Session Management**: Token storage and refresh using Keychain
- **Phone Verification**: Twilio Verify integration for phone number verification
- **Session Lifecycle Management**: Automatic token refresh and expiration handling

## Key Components

### AuthManager
The main authentication manager that coordinates all authentication operations.

```swift
import Auth

let authManager = AuthManager()

// Sign in with Apple
try await authManager.signInWithApple()

// Check authentication status
let isAuthenticated = await authManager.isAuthenticated

// Get current access token
let token = try await authManager.currentAccessToken()

// Start phone verification
let session = try await authManager.startPhoneVerification(phoneNumber: "+1234567890")

// Verify phone code
let isValid = try await authManager.verifyPhoneCode("123456")

// Sign out
await authManager.signOut()
```

### SessionStore
Manages authentication sessions and token storage using Keychain.

```swift
let sessionStore = SessionStore()

// Check if session is valid
let hasValidSession = await sessionStore.hasValidSession()

// Get current user
let user = try await sessionStore.getCurrentUser()

// Refresh token
try await sessionStore.refreshToken()
```

### PhoneVerifier
Protocol for phone verification services with Twilio Verify implementation.

```swift
let phoneVerifier = TwilioPhoneVerifier(
    accountSid: "your_account_sid",
    authToken: "your_auth_token",
    serviceSid: "your_service_sid"
)

// Send verification code
let sessionId = try await phoneVerifier.sendVerificationCode(to: "+1234567890")

// Verify code
let isValid = try await phoneVerifier.verifyCode("123456", sessionId: sessionId)
```

### KeychainHelper
Secure storage for authentication credentials.

```swift
let keychainHelper = KeychainHelper()

// Store session
try await keychainHelper.storeSession(session)

// Load session
let session = try await keychainHelper.loadSession()

// Delete credentials
await keychainHelper.deleteCredentials()
```

## Dependencies

- **AppFoundation**: Provides the `AuthTokenProvider` protocol
- **AuthenticationServices**: Apple's Sign in with Apple framework
- **Security**: Keychain access for secure storage

## Requirements

- iOS 26.0+
- macOS 14.0+
- Swift 6.2+

## Testing

The module includes comprehensive unit tests and mock implementations:

```bash
swift test
```

### Mock Implementations

- `MockPhoneVerifier`: For testing phone verification flows
- Test utilities for session management and authentication flows

## Architecture

The Auth module follows a clean architecture pattern:

1. **AuthManager**: Coordinates authentication operations and maintains state
2. **SessionStore**: Handles session persistence and token management
3. **KeychainHelper**: Provides secure storage abstraction
4. **PhoneVerifier**: Abstracts phone verification services
5. **SessionLifecycleManager**: Manages session expiration and refresh

## Security Considerations

- All sensitive data is stored in Keychain with appropriate access controls
- Tokens are automatically refreshed before expiration
- Phone verification is required for posting functionality
- App Attest integration ready for device attestation

## Integration

The Auth module integrates with other Agora modules:

- **Networking**: Provides authentication tokens via `AuthTokenProvider`
- **Verification**: Uses phone verification for posting requirements
- **Analytics**: Tracks authentication events (when integrated)