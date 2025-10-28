//
//  AuthBridge.swift
//  UIKitBridge
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import AuthenticationServices

#if canImport(UIKit)
import UIKit

/// Bridge for authentication-related UIKit functionality
///
/// Provides SwiftUI-friendly access to UIKit-specific authentication features
/// like window presentation for ASAuthorizationController.
@available(iOS 26.0, *)
public struct AuthBridge: Sendable {
    @MainActor
    public static let shared = AuthBridge()
    
    private init() {}
    
    /// Get the key window for presenting authentication UI
    ///
    /// This is required for `ASAuthorizationControllerPresentationContextProviding`
    /// when using `ASAuthorizationController` for Sign in with Apple.
    ///
    /// - Returns: The key window for presentation
    /// - Throws: `AuthBridgeError.noWindowAvailable` if no suitable window is found
    @MainActor
    public static func getKeyWindow() throws -> UIWindow {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first else {
            throw AuthBridgeError.noWindowAvailable
        }
        return window
    }
    
    /// Get presentation anchor for ASAuthorizationController
    ///
    /// Convenience method that returns ASPresentationAnchor (typealias for UIWindow on iOS)
    /// for use with ASAuthorizationControllerPresentationContextProviding.
    ///
    /// - Returns: The presentation anchor window
    /// - Throws: `AuthBridgeError.noWindowAvailable` if no suitable window is found
    @MainActor
    public static func getPresentationAnchor() throws -> ASPresentationAnchor {
        return try getKeyWindow()
    }
}

/// Errors that can occur when using AuthBridge
public enum AuthBridgeError: Error, LocalizedError {
    case noWindowAvailable
    
    public var errorDescription: String? {
        switch self {
        case .noWindowAvailable:
            return "No window available for authentication presentation"
        }
    }
}

#else
// Non-UIKit platforms (macOS, etc.)
@available(iOS 26.0, *)
public struct AuthBridge: Sendable {
    @MainActor
    public static let shared = AuthBridge()
    
    private init() {}
    
    @MainActor
    public static func getPresentationAnchor() throws -> ASPresentationAnchor {
        throw AuthBridgeError.notSupported
    }
}

public enum AuthBridgeError: Error, LocalizedError {
    case notSupported
    
    public var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Sign in with Apple presentation is not supported on this platform"
        }
    }
}
#endif

// MARK: - SwiftUI Alternative Documentation

/// **SwiftUI Alternative Available**
///
/// For new implementations, consider using SwiftUI's native `SignInWithAppleButton`:
///
/// ```swift
/// import AuthenticationServices
///
/// SignInWithAppleButton(
///     onRequest: { request in
///         request.requestedScopes = [.fullName, .email]
///     },
///     onCompletion: { result in
///         switch result {
///         case .success(let authorization):
///             // Handle authorization
///         case .failure(let error):
///             // Handle error
///         }
///     }
/// )
/// .frame(width: 200, height: 50)
/// ```
///
/// **When to use AuthBridge vs SignInWithAppleButton:**
///
/// - **Use AuthBridge**: When using `ASAuthorizationController` directly for:
///   - More control over the authorization flow
///   - Custom delegate handling
///   - Integration with existing service layer
///   - Need to support continuation-based async/await patterns
///
/// - **Use SignInWithAppleButton**: When:
///   - Building new UI flows from scratch
///   - Want simpler SwiftUI integration
///   - Don't need custom authorization controller behavior
///   - Prefer declarative SwiftUI patterns
///
/// The current implementation uses `ASAuthorizationController` for better service
/// layer integration and async/await support via continuations.


