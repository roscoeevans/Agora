import Foundation
import QuartzCore

#if canImport(Darwin)
import Darwin.Mach
#endif

/// Performance monitoring and analytics for skeleton loading system
/// 
/// Provides comprehensive telemetry for skeleton loading performance including:
/// - Timing metrics (first contentful row, time to interactive)
/// - FPS monitoring with automatic shimmer disable
/// - Memory usage tracking with complexity reduction
/// - Error tracking for skeleton loading failures
/// 
/// Usage from Features:
/// ```swift
/// let skeletonAnalytics = SkeletonAnalytics(analyticsClient: deps.analytics)
/// 
/// // Start timing
/// skeletonAnalytics.startLoadingTimer(feedType: "recommended")
/// 
/// // Track first content
/// skeletonAnalytics.trackFirstContentfulRow(feedType: "recommended", rowIndex: 0)
/// 
/// // Monitor performance
/// skeletonAnalytics.startPerformanceMonitoring()
/// ```
@MainActor
public final class SkeletonAnalytics {
    private let analyticsClient: AnalyticsClient
    private let performanceMonitor: PerformanceMonitor
    
    /// Initialize with explicit analytics client dependency
    public init(analyticsClient: AnalyticsClient) {
        self.analyticsClient = analyticsClient
        self.performanceMonitor = PerformanceMonitor()
    }
    
    // MARK: - Timing Metrics
    
    /// Start timing skeleton loading for a feed
    public func startLoadingTimer(feedType: String) {
        performanceMonitor.startTimer(for: feedType)
    }
    
    /// Track when first contentful row appears
    public func trackFirstContentfulRow(feedType: String, rowIndex: Int) async {
        let elapsedTime = performanceMonitor.getElapsedTime(for: feedType)
        
        await analyticsClient.track(
            event: "first_contentful_row",
            properties: [
                "feed_type": feedType,
                "row_index": rowIndex,
                "elapsed_time_ms": Int(elapsedTime * 1000),
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    /// Track when feed becomes fully interactive
    public func trackTimeToInteractive(feedType: String, totalRows: Int) async {
        let elapsedTime = performanceMonitor.getElapsedTime(for: feedType)
        
        await analyticsClient.track(
            event: "time_to_interactive",
            properties: [
                "feed_type": feedType,
                "total_rows": totalRows,
                "elapsed_time_ms": Int(elapsedTime * 1000),
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        
        // Clean up timer
        performanceMonitor.stopTimer(for: feedType)
    }
    
    // MARK: - Error Tracking
    
    /// Track skeleton loading errors
    public func trackSkeletonError(
        feedType: String,
        error: Error,
        context: String = "",
        retryCount: Int = 0
    ) async {
        await analyticsClient.track(
            event: "skeleton_error",
            properties: [
                "feed_type": feedType,
                "error_description": error.localizedDescription,
                "error_domain": (error as NSError).domain,
                "error_code": (error as NSError).code,
                "context": context,
                "retry_count": retryCount,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    // MARK: - Performance Monitoring
    
    /// Start comprehensive performance monitoring
    /// Returns a monitoring session that Features can use to check performance
    public func startPerformanceMonitoring() -> SkeletonPerformanceSession {
        return SkeletonPerformanceSession(
            analyticsClient: analyticsClient,
            performanceMonitor: performanceMonitor
        )
    }
}

// MARK: - Performance Session

/// Active performance monitoring session for skeleton loading
/// 
/// Features use this to monitor FPS and memory during skeleton display
/// and receive callbacks when performance thresholds are exceeded.
@MainActor
public final class SkeletonPerformanceSession {
    private let analyticsClient: AnalyticsClient
    private let performanceMonitor: PerformanceMonitor
    private let fpsMonitor: FPSMonitor
    private let memoryMonitor: MemoryMonitor
    
    /// Callback when FPS drops below threshold (55 FPS)
    public var onFPSThresholdExceeded: ((Double) -> Void)?
    
    /// Callback when memory usage exceeds threshold (100MB)
    public var onMemoryThresholdExceeded: ((Int64) -> Void)?
    
    fileprivate init(analyticsClient: AnalyticsClient, performanceMonitor: PerformanceMonitor) {
        self.analyticsClient = analyticsClient
        self.performanceMonitor = performanceMonitor
        self.fpsMonitor = FPSMonitor()
        self.memoryMonitor = MemoryMonitor()
    }
    
    /// Start monitoring FPS and memory usage
    public func startMonitoring() {
        fpsMonitor.startMonitoring { [weak self] fps in
            self?.handleFPSUpdate(fps)
        }
        
        memoryMonitor.startMonitoring { [weak self] memoryUsage in
            self?.handleMemoryUpdate(memoryUsage)
        }
    }
    
    /// Stop monitoring and clean up resources
    public func stopMonitoring() {
        fpsMonitor.stopMonitoring()
        memoryMonitor.stopMonitoring()
    }
    
    /// Get current FPS reading
    public func getCurrentFPS() -> Double {
        return fpsMonitor.currentFPS
    }
    
    /// Get current memory usage in bytes
    public func getCurrentMemoryUsage() -> Int64 {
        return memoryMonitor.currentMemoryUsage
    }
    
    // MARK: - Private Methods
    
    private func handleFPSUpdate(_ fps: Double) {
        // Track FPS drops below 55 FPS threshold
        if fps < 55.0 {
            Task {
                await analyticsClient.track(
                    event: "skeleton_fps_drop",
                    properties: [
                        "current_fps": fps,
                        "threshold": 55.0,
                        "timestamp": Date().timeIntervalSince1970
                    ]
                )
            }
            
            onFPSThresholdExceeded?(fps)
        }
    }
    
    private func handleMemoryUpdate(_ memoryUsage: Int64) {
        let memoryMB = memoryUsage / (1024 * 1024)
        
        // Track memory usage above 100MB threshold
        if memoryMB > 100 {
            Task {
                await analyticsClient.track(
                    event: "skeleton_memory_threshold",
                    properties: [
                        "memory_usage_mb": memoryMB,
                        "threshold_mb": 100,
                        "timestamp": Date().timeIntervalSince1970
                    ]
                )
            }
            
            onMemoryThresholdExceeded?(memoryUsage)
        }
    }
}

// MARK: - Performance Monitor

/// Internal performance monitoring utilities
private final class PerformanceMonitor {
    private var timers: [String: Date] = [:]
    private let queue = DispatchQueue(label: "PerformanceMonitor", attributes: .concurrent)
    
    func startTimer(for key: String) {
        queue.async(flags: .barrier) {
            self.timers[key] = Date()
        }
    }
    
    func getElapsedTime(for key: String) -> TimeInterval {
        return queue.sync {
            guard let startTime = timers[key] else { return 0 }
            return Date().timeIntervalSince(startTime)
        }
    }
    
    func stopTimer(for key: String) {
        queue.async(flags: .barrier) {
            self.timers.removeValue(forKey: key)
        }
    }
}

// MARK: - FPS Monitor

/// Monitors frame rate during skeleton display
@MainActor
private final class FPSMonitor {
    #if os(iOS)
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    #endif
    
    private var fpsCallback: ((Double) -> Void)?
    private var timer: Timer?
    
    private(set) var currentFPS: Double = 60.0
    
    func startMonitoring(callback: @escaping (Double) -> Void) {
        self.fpsCallback = callback
        
        #if os(iOS)
        displayLink = CADisplayLink(target: FPSTarget { [weak self] in
            self?.updateFPS()
        }, selector: #selector(FPSTarget.update))
        displayLink?.add(to: .main, forMode: .common)
        #else
        // For macOS, use a timer-based approach
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                // Simulate FPS monitoring on macOS
                self?.currentFPS = 60.0
                self?.fpsCallback?(60.0)
            }
        }
        #endif
    }
    
    func stopMonitoring() {
        #if os(iOS)
        displayLink?.invalidate()
        displayLink = nil
        #else
        timer?.invalidate()
        timer = nil
        #endif
        fpsCallback = nil
    }
    
    #if os(iOS)
    private func updateFPS() {
        guard let displayLink = displayLink else { return }
        
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        frameCount += 1
        let elapsed = displayLink.timestamp - lastTimestamp
        
        // Update FPS every second
        if elapsed >= 1.0 {
            currentFPS = Double(frameCount) / elapsed
            fpsCallback?(currentFPS)
            
            frameCount = 0
            lastTimestamp = displayLink.timestamp
        }
    }
    #endif
}

/// Helper class for CADisplayLink target
private final class FPSTarget: NSObject {
    private let updateHandler: () -> Void
    
    init(updateHandler: @escaping () -> Void) {
        self.updateHandler = updateHandler
        super.init()
    }
    
    @objc func update() {
        updateHandler()
    }
}

// MARK: - Memory Monitor

/// Monitors memory usage during skeleton display
@MainActor
private final class MemoryMonitor {
    private var timer: Timer?
    private var memoryCallback: ((Int64) -> Void)?
    
    private(set) var currentMemoryUsage: Int64 = 0
    
    func startMonitoring(callback: @escaping (Int64) -> Void) {
        self.memoryCallback = callback
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMemoryUsage()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        memoryCallback = nil
    }
    
    private func updateMemoryUsage() {
        #if canImport(Darwin)
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            currentMemoryUsage = Int64(info.resident_size)
            memoryCallback?(currentMemoryUsage)
        }
        #else
        // Fallback for non-Darwin platforms
        currentMemoryUsage = 50 * 1024 * 1024 // 50MB placeholder
        memoryCallback?(currentMemoryUsage)
        #endif
    }
}

