import Foundation
import AppFoundation

/// Fake analytics client for testing
/// 
/// This is a lightweight in-memory implementation that records all analytics calls
/// for verification in tests. It's deterministic and preferred over mocks.
public final class AnalyticsClientFake: AnalyticsClient, @unchecked Sendable {
    // MARK: - Recorded Calls
    
    public struct IdentifyCall: Equatable, Sendable {
        public let userId: String
        public let properties: [String: String] // Simplified for Equatable conformance
        
        public init(userId: String, properties: [String: String]) {
            self.userId = userId
            self.properties = properties
        }
    }
    
    public struct TrackCall: Equatable, Sendable {
        public let event: String
        public let properties: [String: String] // Simplified for Equatable conformance
        
        public init(event: String, properties: [String: String]) {
            self.event = event
            self.properties = properties
        }
    }
    
    // Thread-safe storage using actor isolation
    private let storage: Storage
    
    private actor Storage {
        var identifyCalls: [IdentifyCall] = []
        var trackCalls: [TrackCall] = []
        var setPropertiesCalls: [[String: String]] = []
        var resetCallCount = 0
        var flushCallCount = 0
        
        func recordIdentify(userId: String, properties: [String: String]) {
            identifyCalls.append(IdentifyCall(userId: userId, properties: properties))
        }
        
        func recordTrack(event: String, properties: [String: String]) {
            trackCalls.append(TrackCall(event: event, properties: properties))
        }
        
        func recordSetProperties(_ properties: [String: String]) {
            setPropertiesCalls.append(properties)
        }
        
        func recordReset() {
            resetCallCount += 1
        }
        
        func recordFlush() {
            flushCallCount += 1
        }
        
        func getIdentifyCalls() -> [IdentifyCall] {
            identifyCalls
        }
        
        func getTrackCalls() -> [TrackCall] {
            trackCalls
        }
        
        func getSetPropertiesCalls() -> [[String: String]] {
            setPropertiesCalls
        }
        
        func getResetCallCount() -> Int {
            resetCallCount
        }
        
        func getFlushCallCount() -> Int {
            flushCallCount
        }
        
        func clear() {
            identifyCalls.removeAll()
            trackCalls.removeAll()
            setPropertiesCalls.removeAll()
            resetCallCount = 0
            flushCallCount = 0
        }
    }
    
    // MARK: - Initialization
    
    public init() {
        self.storage = Storage()
    }
    
    // MARK: - AnalyticsClient Conformance
    
    public func identify(userId: String, properties: [String: Any]) async {
        let stringProps = properties.compactMapValues { "\($0)" }
        await storage.recordIdentify(userId: userId, properties: stringProps)
    }
    
    public func track(event: String, properties: [String: Any]) async {
        let stringProps = properties.compactMapValues { "\($0)" }
        await storage.recordTrack(event: event, properties: stringProps)
    }
    
    public func setUserProperties(_ properties: [String: Any]) async {
        let stringProps = properties.compactMapValues { "\($0)" }
        await storage.recordSetProperties(stringProps)
    }
    
    public func reset() async {
        await storage.recordReset()
    }
    
    public func flush() async {
        await storage.recordFlush()
    }
    
    // MARK: - Test Helpers
    
    /// Returns all recorded identify calls
    public func identifyCalls() async -> [IdentifyCall] {
        await storage.getIdentifyCalls()
    }
    
    /// Returns all recorded track calls
    public func trackCalls() async -> [TrackCall] {
        await storage.getTrackCalls()
    }
    
    /// Returns all recorded set properties calls
    public func setPropertiesCalls() async -> [[String: String]] {
        await storage.getSetPropertiesCalls()
    }
    
    /// Returns count of reset calls
    public func resetCallCount() async -> Int {
        await storage.getResetCallCount()
    }
    
    /// Returns count of flush calls
    public func flushCallCount() async -> Int {
        await storage.getFlushCallCount()
    }
    
    /// Clears all recorded calls
    public func clear() async {
        await storage.clear()
    }
    
    /// Convenience: Check if a specific event was tracked
    public func didTrack(event: String) async -> Bool {
        let calls = await trackCalls()
        return calls.contains { $0.event == event }
    }
    
    /// Convenience: Check if user was identified
    public func didIdentify(userId: String) async -> Bool {
        let calls = await identifyCalls()
        return calls.contains { $0.userId == userId }
    }
}

