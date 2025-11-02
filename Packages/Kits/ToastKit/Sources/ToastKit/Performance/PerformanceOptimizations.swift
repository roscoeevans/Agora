import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Performance optimization utilities for ToastKit
#if canImport(UIKit) && !os(macOS)
public final class ToastPerformanceManager: ObservableObject, @unchecked Sendable {
    
    // MARK: - Singleton
    
    public static let shared = ToastPerformanceManager()
    
    // MARK: - Properties
    
    /// Cache for reusable blur views to minimize layer creation
    private let blurViewCache = NSCache<NSString, UIVisualEffectView>()
    
    /// Cache for rendered SF Symbol textures
    private let symbolTextureCache = NSCache<NSString, UIImage>()
    
    /// Weak references to active scenes for memory management
    private var activeScenes: NSHashTable<UIScene> = NSHashTable.weakObjects()
    
    /// Timer references for proper invalidation
    private var activeTimers: Set<Timer> = []
    
    /// Current performance mode based on system state
    @Published private(set) var performanceMode: PerformanceMode = .standard
    
    /// Queue for thread-safe operations
    private let queue = DispatchQueue(label: "com.agora.toast.performance", qos: .userInitiated)
    
    /// Maximum number of concurrent blur layers allowed
    private let maxBlurLayers: Int
    
    /// Whether to respect Low Power Mode
    private let respectLowPowerMode: Bool
    
    // MARK: - Initialization
    
    private init(
        maxBlurLayers: Int = 3,
        respectLowPowerMode: Bool = true
    ) {
        self.maxBlurLayers = maxBlurLayers
        self.respectLowPowerMode = respectLowPowerMode
        
        // Configure caches
        blurViewCache.countLimit = maxBlurLayers
        symbolTextureCache.countLimit = 50
        
        setupPerformanceMonitoring()
        updatePerformanceMode()
    }
    
    // MARK: - Public API
    
    /// Get or create a reusable blur view
    public func getBlurView(
        style: UIBlurEffect.Style,
        intensity: CGFloat = 1.0
    ) -> UIVisualEffectView {
        let keyString = "\(style.rawValue)_\(intensity)" as NSString
        
        if let cachedView = blurViewCache.object(forKey: keyString) {
            // Reset any previous configuration
            DispatchQueue.main.async {
                cachedView.alpha = 1.0
                cachedView.transform = .identity
            }
            return cachedView
        }
        
        // Create new blur view with performance optimizations
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        // Apply Low Power Mode adaptations
        if performanceMode == .lowPower {
            blurView.alpha = 0.8 // Reduce blur intensity
        }
        
        blurViewCache.setObject(blurView, forKey: keyString)
        return blurView
    }
    
    /// Get cached SF Symbol texture or create new one
    public func getSymbolTexture(
        systemName: String,
        size: CGFloat,
        weight: UIImage.SymbolWeight = .medium,
        tintColor: UIColor = .label
    ) -> UIImage? {
        let keyString = "\(systemName)_\(size)_\(weight.rawValue)_\(tintColor.description)" as NSString
        
        if let cachedImage = symbolTextureCache.object(forKey: keyString) {
            return cachedImage
        }
        
        // Create new symbol image with optimizations
        guard let symbolImage = UIImage(systemName: systemName) else {
            return nil
        }
        
        let configuration = UIImage.SymbolConfiguration(
            pointSize: size,
            weight: weight
        )
        
        guard let configuredImage = symbolImage.applyingSymbolConfiguration(configuration) else {
            return nil
        }
        
        // Render with tint color
        let renderer = UIGraphicsImageRenderer(size: configuredImage.size)
        let tintedImage = renderer.image { context in
            tintColor.setFill()
            configuredImage.draw(at: .zero)
            context.cgContext.setBlendMode(.sourceAtop)
            context.fill(CGRect(origin: .zero, size: configuredImage.size))
        }
        
        symbolTextureCache.setObject(tintedImage, forKey: keyString)
        return tintedImage
    }
    
    /// Register a scene for memory management
    public func registerScene(_ scene: UIScene) {
        queue.async { [weak self] in
            self?.activeScenes.add(scene)
        }
    }
    
    /// Unregister a scene and clean up resources
    public func unregisterScene(_ scene: UIScene) {
        queue.async { [weak self] in
            self?.activeScenes.remove(scene)
            self?.cleanupResourcesForScene(scene)
        }
    }
    
    /// Register a timer for proper cleanup
    public func registerTimer(_ timer: Timer) {
        queue.async { [weak self] in
            self?.activeTimers.insert(timer)
        }
    }
    
    /// Unregister and invalidate a timer
    public func unregisterTimer(_ timer: Timer) {
        timer.invalidate()
        queue.async { [weak self] in
            self?.activeTimers.remove(timer)
        }
    }
    
    /// Get current performance-adapted shadow configuration
    public func adaptiveShadowConfig() -> ShadowConfig {
        switch performanceMode {
        case .standard:
            return ShadowConfig(
                color: UIColor.black.withAlphaComponent(0.1),
                radius: 8.0,
                offset: CGSize(width: 0, height: 4)
            )
        case .lowPower:
            return ShadowConfig(
                color: UIColor.black.withAlphaComponent(0.05),
                radius: 2.0,
                offset: CGSize(width: 0, height: 1)
            )
        case .highPerformance:
            return ShadowConfig(
                color: UIColor.black.withAlphaComponent(0.15),
                radius: 12.0,
                offset: CGSize(width: 0, height: 6)
            )
        }
    }
    
    /// Get performance-adapted blur radius
    public func adaptiveBlurRadius() -> CGFloat {
        switch performanceMode {
        case .standard:
            return 8.0
        case .lowPower:
            return 4.0
        case .highPerformance:
            return 12.0
        }
    }
    
    /// Clean up all cached resources
    public func clearCaches() {
        blurViewCache.removeAllObjects()
        symbolTextureCache.removeAllObjects()
    }
    
    /// Force cleanup of unused resources
    public func performMemoryCleanup() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Clean up caches - NSCache handles this automatically based on memory pressure
            // But we can force some cleanup if needed
            
            // Clean up inactive scenes
            self.cleanupInactiveScenes()
            
            // Invalidate orphaned timers
            self.cleanupOrphanedTimers()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupPerformanceMonitoring() {
        // Monitor Low Power Mode changes
        NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePerformanceMode()
        }
        
        // Monitor memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.performMemoryCleanup()
        }
        
        // Monitor app lifecycle
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidEnterBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillEnterForeground()
        }
    }
    
    private func updatePerformanceMode() {
        let newMode: PerformanceMode
        
        if respectLowPowerMode && ProcessInfo.processInfo.isLowPowerModeEnabled {
            newMode = .lowPower
        } else {
            // Could add logic for high performance mode detection
            newMode = .standard
        }
        
        if performanceMode != newMode {
            performanceMode = newMode
            adaptCachesForPerformanceMode()
        }
    }
    
    private func adaptCachesForPerformanceMode() {
        switch performanceMode {
        case .lowPower:
            // Reduce cache sizes in low power mode
            if blurViewCache.count > 1 {
                let keysToRemove = Array(blurViewCache.keys.dropFirst(1))
                for key in keysToRemove {
                    blurViewCache.removeValue(forKey: key)
                }
            }
            
            if symbolTextureCache.count > 20 {
                let keysToRemove = Array(symbolTextureCache.keys.prefix(symbolTextureCache.count - 20))
                for key in keysToRemove {
                    symbolTextureCache.removeValue(forKey: key)
                }
            }
            
        case .standard, .highPerformance:
            // Normal cache behavior
            break
        }
    }
    
    private func cleanupResourcesForScene(_ scene: UIScene) {
        // Remove any scene-specific cached resources
        // This is a placeholder for scene-specific cleanup if needed
    }
    
    private func cleanupInactiveScenes() {
        // NSHashTable automatically removes deallocated objects
        // This method can be used for additional cleanup if needed
    }
    
    private func cleanupOrphanedTimers() {
        let orphanedTimers = activeTimers.filter { !$0.isValid }
        for timer in orphanedTimers {
            activeTimers.remove(timer)
        }
    }
    
    private func handleAppDidEnterBackground() {
        // Aggressive cleanup when app goes to background
        performMemoryCleanup()
        
        // Pause any non-critical operations
        for timer in activeTimers {
            if timer.isValid {
                timer.fireDate = Date.distantFuture
            }
        }
    }
    
    private func handleAppWillEnterForeground() {
        // Resume operations when app comes to foreground
        updatePerformanceMode()
        
        // Resume timers
        for timer in activeTimers {
            if timer.isValid && timer.fireDate == Date.distantFuture {
                timer.fireDate = Date()
            }
        }
    }
}

// MARK: - Supporting Types

/// Performance mode based on system state
public enum PerformanceMode: Sendable {
    case standard
    case lowPower
    case highPerformance
}



/// Shadow configuration for performance adaptation
public struct ShadowConfig {
    public let color: UIColor
    public let radius: CGFloat
    public let offset: CGSize
    
    public init(color: UIColor, radius: CGFloat, offset: CGSize) {
        self.color = color
        self.radius = radius
        self.offset = offset
    }
}

// MARK: - SwiftUI Integration



/// View modifier for performance-optimized toasts
public struct PerformanceOptimizedToastModifier: ViewModifier {
    @Environment(\.toastPerformanceManager) private var performanceManager
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                // Register any scene-specific resources if needed
            }
            .onDisappear {
                // Clean up resources when view disappears
                performanceManager.performMemoryCleanup()
            }
    }
}

public extension View {
    /// Apply performance optimizations to toast views
    func performanceOptimizedToast() -> some View {
        modifier(PerformanceOptimizedToastModifier())
    }
}

#else
// Placeholder for non-UIKit platforms
public final class ToastPerformanceManager: ObservableObject, @unchecked Sendable {
    public static let shared = ToastPerformanceManager()
    
    @Published private(set) var performanceMode: PerformanceMode = .standard
    
    private init() {}
    
    public func getBlurView(style: Any, intensity: CGFloat = 1.0) -> Any? { return nil }
    public func getSymbolTexture(systemName: String, size: CGFloat, weight: Any = 0, tintColor: Any = 0) -> Any? { return nil }
    public func registerScene(_ scene: Any) {}
    public func unregisterScene(_ scene: Any) {}
    public func registerTimer(_ timer: Timer) {}
    public func unregisterTimer(_ timer: Timer) {}
    public func adaptiveShadowConfig() -> ShadowConfig {
        return ShadowConfig(color: Color.black, radius: 8.0, offset: CGSize(width: 0, height: 4))
    }
    public func adaptiveBlurRadius() -> CGFloat { return 8.0 }
    public func clearCaches() {}
    public func performMemoryCleanup() {}
}
#endif

/// Performance mode based on system state
public enum PerformanceMode: Sendable, Equatable {
    case standard
    case lowPower
    case highPerformance
}

/// Shadow configuration for performance adaptation
public struct ShadowConfig {
    #if canImport(UIKit) && !os(macOS)
    public let color: UIColor
    #else
    public let color: Color
    #endif
    public let radius: CGFloat
    public let offset: CGSize
    
    #if canImport(UIKit) && !os(macOS)
    public init(color: UIColor, radius: CGFloat, offset: CGSize) {
        self.color = color
        self.radius = radius
        self.offset = offset
    }
    #else
    public init(color: Color, radius: CGFloat, offset: CGSize) {
        self.color = color
        self.radius = radius
        self.offset = offset
    }
    #endif
}

/// Environment key for performance manager
public struct ToastPerformanceManagerKey: EnvironmentKey {
    public static let defaultValue: ToastPerformanceManager = .shared
}

public extension EnvironmentValues {
    var toastPerformanceManager: ToastPerformanceManager {
        get { self[ToastPerformanceManagerKey.self] }
        set { self[ToastPerformanceManagerKey.self] = newValue }
    }
}

/// View modifier for performance-optimized toasts
public struct PerformanceOptimizedToastModifier: ViewModifier {
    @Environment(\.toastPerformanceManager) private var performanceManager
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                // Register any scene-specific resources if needed
            }
            .onDisappear {
                // Clean up resources when view disappears
                performanceManager.performMemoryCleanup()
            }
    }
}

public extension View {
    /// Apply performance optimizations to toast views
    func performanceOptimizedToast() -> some View {
        modifier(PerformanceOptimizedToastModifier())
    }
}