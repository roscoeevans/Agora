import SwiftUI
import AppFoundation

/// Factory for creating toast services with proper dependency injection
public struct ToastServiceFactory {
    
    // MARK: - Service Creation
    
    /// Creates a toast manager with appropriate configuration for the current environment
    /// - Parameter policy: Optional policy override, defaults to environment-appropriate policy
    /// - Returns: Configured ToastManager instance
    public static func createToastManager(policy: ToastPolicy? = nil) -> ToastManager {
        let effectivePolicy = policy ?? defaultPolicy()
        
        let policyName = AppConfig.isDevelopment ? "testing" : "default"
        print("[ToastServiceFactory] Creating toast manager with \(policyName) policy")
        
        // Create scene manager for multi-window support
        let sceneManager = MainActor.assumeIsolated {
            ToastSceneManager()
        }
        
        // Create toast manager with policy and scene manager
        let manager = ToastManager(
            policy: effectivePolicy,
            telemetry: effectivePolicy.telemetry,
            sceneManager: sceneManager
        )
        
        return manager
    }
    
    /// Creates a complete toast system with manager, scene manager, and policy
    /// - Parameter policy: Optional policy override
    /// - Returns: Tuple containing (manager, sceneManager, policy)
    public static func createToastSystem(policy: ToastPolicy? = nil) -> (manager: ToastManager, sceneManager: ToastSceneManager, policy: ToastPolicy) {
        let effectivePolicy = policy ?? defaultPolicy()
        
        let sceneManager = MainActor.assumeIsolated {
            ToastSceneManager()
        }
        
        let manager = ToastManager(
            policy: effectivePolicy,
            telemetry: effectivePolicy.telemetry,
            sceneManager: sceneManager
        )
        
        return (manager: manager, sceneManager: sceneManager, policy: effectivePolicy)
    }
    
    // MARK: - Environment Integration
    
    /// Creates a view modifier that configures the complete toast system
    /// - Parameter policy: Optional policy override
    /// - Returns: ViewModifier that sets up toast environment
    public static func toastSystemModifier(policy: ToastPolicy? = nil) -> some ViewModifier {
        ToastSystemModifier(policy: policy)
    }
    
    // MARK: - Private Helpers
    
    private static func defaultPolicy() -> ToastPolicy {
        // Use testing policy in development for faster feedback
        // Use default policy in staging and production
        if AppConfig.isDevelopment {
            return .testing
        } else {
            return .default
        }
    }
}

// MARK: - View Modifier

private struct ToastSystemModifier: ViewModifier {
    let policy: ToastPolicy?
    
    func body(content: Content) -> some View {
        let system = ToastServiceFactory.createToastSystem(policy: policy)
        
        content
            .toastProvider(system.manager)
            .toastSceneManager(system.sceneManager)
            .toastPolicy(system.policy)
            .onAppear {
                system.manager.setSceneManager(system.sceneManager)
            }
    }
}

// MARK: - View Extensions

public extension View {
    /// Configure the complete toast system with automatic environment detection
    /// - Parameter policy: Optional policy override
    /// - Returns: View configured with toast system
    func configureToastSystem(policy: ToastPolicy? = nil) -> some View {
        modifier(ToastServiceFactory.toastSystemModifier(policy: policy))
    }
    
    /// Configure toast system with explicit components
    /// - Parameters:
    ///   - manager: Toast manager instance
    ///   - sceneManager: Scene manager instance
    ///   - policy: Policy configuration
    /// - Returns: View configured with toast system
    func configureToastSystem(
        manager: ToastManager,
        sceneManager: ToastSceneManager,
        policy: ToastPolicy
    ) -> some View {
        self
            .toastProvider(manager)
            .toastSceneManager(sceneManager)
            .toastPolicy(policy)
            .onAppear {
                manager.setSceneManager(sceneManager)
            }
    }
}

// MARK: - Singleton Access (Optional)

/// Singleton toast manager for simple use cases
/// Note: For multi-window apps, prefer dependency injection
@MainActor
public final class ToastService: ObservableObject {
    
    /// Shared instance for simple use cases
    public static let shared = ToastService()
    
    /// The underlying toast manager
    public let manager: ToastManager
    
    /// The scene manager
    public let sceneManager: ToastSceneManager
    
    /// The policy configuration
    public let policy: ToastPolicy
    
    private init() {
        let system = ToastServiceFactory.createToastSystem()
        self.manager = system.manager
        self.sceneManager = system.sceneManager
        self.policy = system.policy
    }
    
    /// Configure a view with the shared toast system
    public func configure<Content: View>(_ content: Content) -> some View {
        content.configureToastSystem(
            manager: manager,
            sceneManager: sceneManager,
            policy: policy
        )
    }
}

// MARK: - Environment Value Extensions

public extension EnvironmentValues {
    /// Access to the shared toast service (convenience for simple use cases)
    @MainActor
    var sharedToastService: ToastService {
        ToastService.shared
    }
}