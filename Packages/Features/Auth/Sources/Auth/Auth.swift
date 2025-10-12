import Foundation

/// Auth module - Authentication and onboarding functionality
///
/// This module provides:
/// - Sign in with Apple integration
/// - User profile creation and management
/// - Handle validation and availability checking
/// - Onboarding flow UI
///
/// ## Usage
///
/// ```swift
/// import Auth
///
/// // Create auth state manager
/// let authManager = AuthStateManager()
///
/// // Check current auth state
/// await authManager.checkAuthState()
///
/// // Sign in with Apple
/// try await authManager.signInWithApple()
///
/// // Create profile
/// try await authManager.createProfile(
///     handle: "johndoe",
///     displayHandle: "JohnDoe",
///     displayName: "John Doe"
/// )
/// ```
///
/// ## Views
///
/// - `WelcomeView`: Landing screen with Sign in with Apple
/// - `OnboardingView`: Multi-step profile creation flow
/// - `HandleInputView`: Handle selection with real-time validation
///
/// ## State Management
///
/// The module uses `AuthStateManager` as an `@Observable` object that tracks:
/// - Authentication state (initializing, unauthenticated, authenticatedNoProfile, authenticated)
/// - Current user profile
/// - Loading and error states
///
/// ## Architecture
///
/// The Auth module follows a clean architecture with:
/// - **Models**: UserProfile, AuthState
/// - **Services**: HandleValidator (actor for thread-safe validation)
/// - **State**: AuthStateManager (@Observable for SwiftUI integration)
/// - **Views**: SwiftUI views following Apple design guidelines

public enum Auth {
    /// Module version
    public static let version = "1.0.0"
}

