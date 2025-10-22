# Auth Module

Authentication and onboarding functionality for Agora iOS app.

## Overview

The Auth module provides complete authentication flow including Sign in with Apple integration, profile creation, and handle validation. It follows Apple's Human Interface Guidelines with iOS 26's Liquid Glass design aesthetics.

## Features

- ✅ Sign in with Apple integration
- ✅ Real-time handle validation with debouncing
- ✅ Handle uniqueness checking
- ✅ Custom handle capitalization (Twitter-style)
- ✅ Multi-step onboarding flow
- ✅ Observable state management
- ✅ Accessibility support (VoiceOver, Dynamic Type)
- ✅ Apple-style UI with Liquid Glass effects

## Architecture

### State Management

```swift
@Observable
class AuthStateManager {
    enum State {
        case initializing
        case unauthenticated
        case authenticatedNoProfile(userId: String)
        case authenticated(profile: UserProfile)
    }
}
```

### Handle Validation

```swift
actor HandleValidator {
    func validateFormat(_ handle: String) -> HandleFormatValidation
    func checkAvailability(_ handle: String) async throws -> HandleAvailability
}
```

### Models

- `UserProfile`: User profile data
- `AuthState`: Authentication state enum
- `HandleFormatValidation`: Format validation result
- `HandleAvailability`: Availability check result

## Views

### WelcomeView

Landing screen with Sign in with Apple button.

```swift
import Authentication

struct ContentView: View {
    var body: some View {
        WelcomeView()
            .environment(authManager)
    }
}
```

### OnboardingView

Multi-step profile creation flow:
1. Handle selection with real-time validation
2. Display name input

```swift
OnboardingView()
    .environment(authManager)
```

### HandleInputView

Reusable handle input component with validation.

```swift
HandleInputView(
    handle: $handle,
    displayHandle: $displayHandle,
    isValid: $isValid,
    validator: validator
)
```

## Usage

### Check Auth State

```swift
import AuthenticationFeature

let authManager = AuthStateManager()

// Check current state on app launch
await authManager.checkAuthState()

switch authManager.state {
case .unauthenticated:
    // Show welcome screen
case .authenticatedNoProfile:
    // Show onboarding
case .authenticated(let profile):
    // Show main app
}
```

### Sign In with Apple

```swift
do {
    try await authManager.signInWithApple()
} catch {
    // Handle error
}
```

### Create Profile

```swift
try await authManager.createProfile(
    handle: "johndoe",           // lowercase, for uniqueness
    displayHandle: "JohnDoe",    // user's preferred capitalization
    displayName: "John Doe"
)
```

### Handle Validation

```swift
let validator = authManager.getValidator()

// Format validation (instant)
let formatResult = await validator.validateFormat("johndoe")

// Availability check (debounced, calls API)
let availability = try await validator.checkAvailability("johndoe")
if availability.available {
    // Handle is available
} else {
    // Show suggestions
    print(availability.suggestions)
}
```

## Handle System

Agora uses a dual-handle system similar to Twitter:

- **Canonical Handle**: Lowercase, used for uniqueness (`johndoe`)
- **Display Handle**: User's preferred capitalization (`JohnDoe`)

### Validation Rules

- 3-15 characters
- Lowercase letters, numbers, underscores only
- Cannot start with underscore
- Cannot be all numbers
- Reserved handles blocked (admin, system, etc.)

### Debouncing

Handle availability checks are debounced (300ms) to avoid excessive API calls while user is typing.

## Dependencies

- **DesignSystem**: UI components, colors, typography
- **Networking**: API client for profile creation and handle checking
- **AppFoundation**: Auth services, service factory, configuration

## Accessibility

All views support:
- VoiceOver with descriptive labels and hints
- Dynamic Type for text size adjustment
- Reduce Motion for animation preferences
- High contrast mode
- Keyboard navigation

## Testing

```swift
import Authentication
import Testing

@Test func testHandleValidation() async {
    let validator = HandleValidator(apiClient: mockClient)
    
    // Too short
    let result1 = await validator.validateFormat("ab")
    #expect(result1 == .tooShort)
    
    // Valid
    let result2 = await validator.validateFormat("johndoe")
    #expect(result2 == .valid)
}
```

## Design Principles

- **Apple-style UI**: Follows HIG with SF Symbols, system fonts, native controls
- **Liquid Glass**: Uses translucent materials for modern iOS 18+ aesthetic
- **Clear Feedback**: Immediate validation feedback with helpful messages
- **Error Recovery**: Suggestions when handle is taken, clear error messages
- **Progressive Disclosure**: Multi-step flow to avoid overwhelming users

## Future Enhancements

- [ ] Phone number verification
- [ ] Email verification option
- [ ] Profile photo upload during onboarding
- [ ] Bio input during onboarding
- [ ] Import contacts for friend discovery

