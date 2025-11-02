import Foundation

/// Configuration policy for toast behavior and performance
public struct ToastPolicy: Sendable {
    /// Minimum time between toast presentations
    public var minimumInterval: Duration
    
    /// Maximum number of toasts that can be queued
    public var maxQueueSize: Int
    
    /// Time window for coalescing duplicate toasts
    public var coalescingWindow: Duration
    
    /// Delay before interrupting lower priority toasts
    public var criticalInterruptionDelay: Duration
    
    /// Whether to persist critical toasts through app lifecycle
    public var persistCriticalToasts: Bool
    
    /// Maximum number of blur sublayers for performance
    public var maxBlurLayers: Int
    
    /// Whether to adapt rendering for Low Power Mode
    public var respectLowPowerMode: Bool
    
    /// Telemetry provider for analytics
    public let telemetry: ToastTelemetry
    
    public init(
        minimumInterval: Duration = .milliseconds(800),
        maxQueueSize: Int = 10,
        coalescingWindow: Duration = .seconds(2),
        criticalInterruptionDelay: Duration = .milliseconds(120),
        persistCriticalToasts: Bool = true,
        maxBlurLayers: Int = 3,
        respectLowPowerMode: Bool = true,
        telemetry: ToastTelemetry = NoOpToastTelemetry()
    ) {
        self.minimumInterval = minimumInterval
        self.maxQueueSize = maxQueueSize
        self.coalescingWindow = coalescingWindow
        self.criticalInterruptionDelay = criticalInterruptionDelay
        self.persistCriticalToasts = persistCriticalToasts
        self.maxBlurLayers = maxBlurLayers
        self.respectLowPowerMode = respectLowPowerMode
        self.telemetry = telemetry
    }
}

// MARK: - Predefined Policies

public extension ToastPolicy {
    /// Default balanced policy
    static let `default` = ToastPolicy()
    
    /// Aggressive policy for high-frequency notifications
    static let aggressive = ToastPolicy(
        minimumInterval: .milliseconds(400),
        maxQueueSize: 15,
        coalescingWindow: .seconds(1)
    )
    
    /// Conservative policy for minimal interruption
    static let conservative = ToastPolicy(
        minimumInterval: .seconds(1.5),
        maxQueueSize: 5,
        coalescingWindow: .seconds(3)
    )
    
    /// Performance-optimized policy for older devices
    static let performanceOptimized = ToastPolicy(
        minimumInterval: .seconds(1),
        maxQueueSize: 3,
        maxBlurLayers: 1,
        respectLowPowerMode: true
    )
    
    /// Testing policy with no delays
    static let testing = ToastPolicy(
        minimumInterval: .milliseconds(0),
        maxQueueSize: 100,
        coalescingWindow: .milliseconds(0),
        criticalInterruptionDelay: .milliseconds(0),
        persistCriticalToasts: false
    )
}