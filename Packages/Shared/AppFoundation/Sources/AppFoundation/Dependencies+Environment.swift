import SwiftUI

// MARK: - SwiftUI Environment Bridge

/// Environment key for dependency injection
/// 
/// This allows the Dependencies container to be passed through the SwiftUI
/// environment hierarchy, making it available to all views without prop drilling.
/// 
/// This follows the DI rule pattern:
/// - Use Environment ONLY for app-wide services
/// - Feature-specific dependencies should use initializer injection
/// - Dependencies are immutable once set
private struct DependenciesKey: EnvironmentKey {
    static let defaultValue: Dependencies = {
        // In previews, use test dependencies to avoid crashes
        // In production, this should never be reached (app sets deps at root)
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if env["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || env["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1" {
            return .test()
        }
        #endif
        return .production
    }()
}

extension EnvironmentValues {
    /// App-wide dependencies container
    /// 
    /// Usage in views:
    /// ```swift
    /// @Environment(\.deps) private var deps
    /// 
    /// var body: some View {
    ///     ForYouView(
    ///         viewModel: .init(
    ///             networking: deps.networking,
    ///             analytics: deps.analytics
    ///         )
    ///     )
    /// }
    /// ```
    public var deps: Dependencies {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension Dependencies {
    /// Preview dependencies with deterministic fake implementations
    /// Perfect for SwiftUI previews and snapshot tests
    public static var preview: Dependencies {
        return .test()
    }
}
#endif

// Also provide preview outside DEBUG for Xcode Previews
// (Xcode Previews sometimes don't properly set DEBUG flag)
#if !DEBUG
extension Dependencies {
    /// Preview dependencies with deterministic fake implementations
    /// Perfect for SwiftUI previews and snapshot tests
    public static var preview: Dependencies {
        return .production // Fallback to production in release builds
    }
}
#endif

