import SwiftUI

// MARK: - Dependencies Environment Key

/// Environment key for dependency injection
private struct DependenciesKey: EnvironmentKey {
    static let defaultValue: Dependencies = {
        #if DEBUG
        // In debug builds, use test dependencies for previews
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return .test()
        }
        #endif
        // Fallback to production dependencies
        return .production
    }()
}

extension EnvironmentValues {
    /// Access to the app's dependency container
    /// 
    /// Usage:
    /// ```swift
    /// @Environment(\.deps) private var deps
    /// let viewModel = MyViewModel(networking: deps.networking)
    /// ```
    public var deps: Dependencies {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}

// MARK: - Individual Service Environment Keys

/// Environment key for image crop rendering service
private struct ImageCropRenderingKey: EnvironmentKey {
    static let defaultValue: ImageCropRendering? = nil
}

/// Environment key for avatar upload service
private struct AvatarUploadServiceKey: EnvironmentKey {
    static let defaultValue: AvatarUploadService? = nil
}

extension EnvironmentValues {
    /// Direct access to image crop rendering service
    /// 
    /// Usage:
    /// ```swift
    /// @Environment(\.imageCropRendering) private var imageCropRendering
    /// ```
    public var imageCropRendering: ImageCropRendering? {
        get { self[ImageCropRenderingKey.self] ?? deps.imageCropRendering }
        set { self[ImageCropRenderingKey.self] = newValue }
    }
    
    /// Direct access to avatar upload service
    /// 
    /// Usage:
    /// ```swift
    /// @Environment(\.avatarUploadService) private var avatarUploadService
    /// ```
    public var avatarUploadService: AvatarUploadService? {
        get { self[AvatarUploadServiceKey.self] ?? deps.avatarUploadService }
        set { self[AvatarUploadServiceKey.self] = newValue }
    }
}

// MARK: - View Extensions for Dependency Injection

extension View {
    /// Inject dependencies into the environment
    /// 
    /// Usage:
    /// ```swift
    /// ContentView()
    ///     .dependencies(.production)
    /// ```
    public func dependencies(_ deps: Dependencies) -> some View {
        self.environment(\.deps, deps)
    }
    
    /// Inject individual avatar cropper services into the environment
    /// 
    /// Usage:
    /// ```swift
    /// AvatarCropperView(...)
    ///     .avatarCropperServices(
    ///         imageCropRendering: ImageCropRendererLive(),
    ///         avatarUploadService: AvatarUploadServiceLive()
    ///     )
    /// ```
    public func avatarCropperServices(
        imageCropRendering: ImageCropRendering,
        avatarUploadService: AvatarUploadService
    ) -> some View {
        self
            .environment(\.imageCropRendering, imageCropRendering)
            .environment(\.avatarUploadService, avatarUploadService)
    }
    
    /// Inject mock avatar cropper services for testing
    /// 
    /// Usage:
    /// ```swift
    /// AvatarCropperView(...)
    ///     .mockAvatarCropperServices()
    /// ```
    public func mockAvatarCropperServices() -> some View {
        self.avatarCropperServices(
            imageCropRendering: MockImageCropRenderer(),
            avatarUploadService: MockAvatarUploadService()
        )
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension Dependencies {
    /// Convenience factory for SwiftUI previews with avatar cropper services
    public static func preview(
        imageCropRendering: ImageCropRendering? = nil,
        avatarUploadService: AvatarUploadService? = nil
    ) -> Dependencies {
        return .test(
            imageCropRendering: imageCropRendering ?? MockImageCropRenderer(),
            avatarUploadService: avatarUploadService ?? MockAvatarUploadService()
        )
    }
}
#endif