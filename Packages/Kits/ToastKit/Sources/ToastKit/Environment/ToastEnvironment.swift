import SwiftUI

// MARK: - Toast Provider Environment

/// Environment key for accessing toast services
public struct ToastEnvironmentKey: EnvironmentKey {
    public static var defaultValue: ToastsProviding {
        NoOpToastProvider()
    }
}

public extension EnvironmentValues {
    /// Access to toast notification services
    var toasts: ToastsProviding {
        get { self[ToastEnvironmentKey.self] }
        set { self[ToastEnvironmentKey.self] = newValue }
    }
}

// MARK: - Toast Policy Environment

/// Environment key for toast policy configuration
public struct ToastPolicyKey: EnvironmentKey {
    public static let defaultValue = ToastPolicy.default
}

public extension EnvironmentValues {
    /// Toast policy configuration
    var toastPolicy: ToastPolicy {
        get { self[ToastPolicyKey.self] }
        set { self[ToastPolicyKey.self] = newValue }
    }
}

// MARK: - No-Op Provider

/// No-operation toast provider for testing and previews
public final class NoOpToastProvider: ToastsProviding {
    public init() {}
    
    public func show(_ item: ToastItem) async {
        // No-op for testing/previews
    }
    
    public func show(
        _ message: LocalizedStringKey,
        kind: ToastKind,
        options: ToastOptions,
        action: ToastAction?
    ) async {
        // No-op for testing/previews
    }
    
    public func dismiss(id: ToastID) async {
        // No-op for testing/previews
    }
    
    public func dismissAll() async {
        // No-op for testing/previews
    }
}

// MARK: - Environment Modifiers

public extension View {
    /// Provide toast services to the view hierarchy
    func toastProvider(_ provider: ToastsProviding) -> some View {
        environment(\.toasts, provider)
    }
    
    /// Configure toast policy for the view hierarchy
    func toastPolicy(_ policy: ToastPolicy) -> some View {
        environment(\.toastPolicy, policy)
    }
    
    /// Configure complete toast system with manager, scene manager, and policy
    func toastSystem(
        manager: ToastManager,
        sceneManager: ToastSceneManager? = nil,
        policy: ToastPolicy? = nil
    ) -> some View {
        let effectiveSceneManager = sceneManager ?? ToastSceneManager()
        let effectivePolicy = policy ?? .default
        
        return self
            .toastProvider(manager)
            .toastSceneManager(effectiveSceneManager)
            .toastPolicy(effectivePolicy)
            .onAppear {
                manager.setSceneManager(effectiveSceneManager)
            }
    }
}

// MARK: - Convenience Environment Access
// Note: For showing toasts, use the async methods on the toasts provider directly
// Example: Task { await environment.toasts.success("Message") }