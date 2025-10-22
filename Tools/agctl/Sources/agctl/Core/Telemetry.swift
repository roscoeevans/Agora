import Foundation
import ArgumentParser

/// Telemetry system for understanding usage patterns and optimizing agctl
/// Collects anonymous usage data to improve the tool
@MainActor
class Telemetry: @unchecked Sendable {
    static let shared = Telemetry()
    
    private let dataDirectory: URL
    private let configFile: URL
    private var isEnabled: Bool = true
    private var sessionId: String = UUID().uuidString
    private var events: [TelemetryEvent] = []
    
    private init() {
        dataDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".agctl/telemetry")
        
        configFile = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".agctl/telemetry.json")
        
        // Ensure data directory exists
        try? FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        
        // Load configuration
        loadConfiguration()
        
        // Start session
        startSession()
    }
    
    // MARK: - Configuration
    
    private func loadConfiguration() {
        guard FileManager.default.fileExists(atPath: configFile.path) else {
            // Default configuration
            saveConfiguration()
            return
        }
        
        do {
            let data = try Data(contentsOf: configFile)
            let config = try JSONDecoder().decode(TelemetryConfig.self, from: data)
            isEnabled = config.enabled
        } catch {
            Logger.warning("Failed to load telemetry config: \(error)")
            isEnabled = true // Default to enabled
        }
    }
    
    private func saveConfiguration() {
        let config = TelemetryConfig(enabled: isEnabled)
        
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configFile)
        } catch {
            Logger.warning("Failed to save telemetry config: \(error)")
        }
    }
    
    // MARK: - Event Tracking
    
    /// Track a telemetry event
    func track(_ event: String, properties: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        let telemetryEvent = TelemetryEvent(
            sessionId: sessionId,
            event: event,
            properties: properties,
            timestamp: Date()
        )
        
        events.append(telemetryEvent)
        
        // Flush if we have too many events
        if events.count >= 100 {
            flush()
        }
    }
    
    /// Track command execution
    func trackCommand(_ command: String, arguments: [String], duration: TimeInterval?, success: Bool) {
        var properties: [String: Any] = [
            "command": command,
            "argument_count": arguments.count,
            "success": success
        ]
        
        if let duration = duration {
            properties["duration"] = duration
        }
        
        // Add context
        properties["package_name"] = arguments.first
        properties["has_verbose_flag"] = arguments.contains("--verbose")
        properties["has_release_flag"] = arguments.contains("--release")
        
        track("command_executed", properties: properties)
    }
    
    /// Track build performance
    func trackBuild(packageName: String?, duration: TimeInterval, success: Bool, errorType: String? = nil) {
        var properties: [String: Any] = [
            "package_name": packageName ?? "all_packages",
            "duration": duration,
            "success": success
        ]
        
        if let errorType = errorType {
            properties["error_type"] = errorType
        }
        
        track("build_completed", properties: properties)
    }
    
    /// Track test execution
    func trackTest(packageName: String?, duration: TimeInterval, success: Bool, testCount: Int? = nil) {
        var properties: [String: Any] = [
            "package_name": packageName ?? "all_packages",
            "duration": duration,
            "success": success
        ]
        
        if let testCount = testCount {
            properties["test_count"] = testCount
        }
        
        track("test_completed", properties: properties)
    }
    
    /// Track error occurrences
    func trackError(_ error: String, command: String, context: [String: Any] = [:]) {
        var properties: [String: Any] = [
            "error": error,
            "command": command
        ]
        
        properties.merge(context) { _, new in new }
        
        track("error_occurred", properties: properties)
    }
    
    /// Track feature usage
    func trackFeatureUsage(_ feature: String, properties: [String: Any] = [:]) {
        var eventProperties = properties
        eventProperties["feature"] = feature
        
        track("feature_used", properties: eventProperties)
    }
    
    // MARK: - Session Management
    
    private func startSession() {
        track("session_started", properties: [
            "version": AGCTLCommand.configuration.version,
            "platform": "macOS",
            "swift_version": getSwiftVersion()
        ])
    }
    
    func endSession() {
        track("session_ended", properties: [
            "duration": getSessionDuration(),
            "event_count": events.count
        ])
        
        flush()
    }
    
    private func getSessionDuration() -> TimeInterval {
        // This would track from session start
        return 0 // Placeholder
    }
    
    private func getSwiftVersion() -> String {
        do {
            let result = try runProcessSync("/usr/bin/xcrun", arguments: ["swift", "--version"])
            return result.stdout.components(separatedBy: "\n").first ?? "unknown"
        } catch {
            return "unknown"
        }
    }
    
    // MARK: - Data Flushing
    
    private func flush() {
        guard !events.isEmpty else { return }
        
        let eventsToFlush = events
        events.removeAll()
        
        // Save to local file
        saveEventsToFile(eventsToFlush)
        
        // In a real implementation, you might also send to a remote service
        // sendToRemoteService(eventsToFlush)
    }
    
    private func saveEventsToFile(_ events: [TelemetryEvent]) {
        let filename = "events_\(Int(Date().timeIntervalSince1970)).json"
        let fileURL = dataDirectory.appendingPathComponent(filename)
        
        do {
            let data = try JSONEncoder().encode(events)
            try data.write(to: fileURL)
        } catch {
            Logger.warning("Failed to save telemetry events: \(error)")
        }
    }
    
    // MARK: - Analytics
    
    /// Get usage analytics
    func getAnalytics() -> UsageAnalytics {
        let allEvents = loadAllEvents()
        
        return UsageAnalytics(
            totalSessions: countSessions(allEvents),
            totalCommands: countCommands(allEvents),
            mostUsedCommands: getMostUsedCommands(allEvents),
            averageBuildTime: getAverageBuildTime(allEvents),
            errorRate: getErrorRate(allEvents),
            featureUsage: getFeatureUsage(allEvents)
        )
    }
    
    private func loadAllEvents() -> [TelemetryEvent] {
        guard FileManager.default.fileExists(atPath: dataDirectory.path) else { return [] }
        
        var allEvents: [TelemetryEvent] = []
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: dataDirectory.path)
            
            for file in files where file.hasSuffix(".json") {
                let fileURL = dataDirectory.appendingPathComponent(file)
                let data = try Data(contentsOf: fileURL)
                let events = try JSONDecoder().decode([TelemetryEvent].self, from: data)
                allEvents.append(contentsOf: events)
            }
        } catch {
            Logger.warning("Failed to load telemetry events: \(error)")
        }
        
        return allEvents
    }
    
    private func countSessions(_ events: [TelemetryEvent]) -> Int {
        let sessionIds = Set(events.map { $0.sessionId })
        return sessionIds.count
    }
    
    private func countCommands(_ events: [TelemetryEvent]) -> Int {
        return events.filter { $0.event == "command_executed" }.count
    }
    
    private func getMostUsedCommands(_ events: [TelemetryEvent]) -> [String: Int] {
        let commandEvents = events.filter { $0.event == "command_executed" }
        var commandCounts: [String: Int] = [:]
        
        for event in commandEvents {
            if let command = event.properties["command"] as? String {
                commandCounts[command, default: 0] += 1
            }
        }
        
        return commandCounts
    }
    
    private func getAverageBuildTime(_ events: [TelemetryEvent]) -> TimeInterval? {
        let buildEvents = events.filter { $0.event == "build_completed" }
        let durations = buildEvents.compactMap { $0.properties["duration"] as? TimeInterval }
        
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }
    
    private func getErrorRate(_ events: [TelemetryEvent]) -> Double {
        let commandEvents = events.filter { $0.event == "command_executed" }
        let errorEvents = events.filter { $0.event == "error_occurred" }
        
        guard !commandEvents.isEmpty else { return 0.0 }
        return Double(errorEvents.count) / Double(commandEvents.count)
    }
    
    private func getFeatureUsage(_ events: [TelemetryEvent]) -> [String: Int] {
        let featureEvents = events.filter { $0.event == "feature_used" }
        var featureCounts: [String: Int] = [:]
        
        for event in featureEvents {
            if let feature = event.properties["feature"] as? String {
                featureCounts[feature, default: 0] += 1
            }
        }
        
        return featureCounts
    }
    
    // MARK: - Configuration Management
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        saveConfiguration()
        
        if enabled {
            Logger.success("Telemetry enabled")
        } else {
            Logger.info("Telemetry disabled")
        }
    }
    
    func isTelemetryEnabled() -> Bool {
        return isEnabled
    }
    
    func clearData() {
        try? FileManager.default.removeItem(at: dataDirectory)
        try? FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        
        events.removeAll()
        Logger.success("Telemetry data cleared")
    }
}

// MARK: - Supporting Types

struct TelemetryEvent: Codable {
    let sessionId: String
    let event: String
    let properties: [String: Any]
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case sessionId, event, properties, timestamp
    }
    
    init(sessionId: String, event: String, properties: [String: Any], timestamp: Date) {
        self.sessionId = sessionId
        self.event = event
        self.properties = properties
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        event = try container.decode(String.self, forKey: .event)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Decode properties as [String: String] for simplicity
        let stringProperties = try container.decodeIfPresent([String: String].self, forKey: .properties) ?? [:]
        properties = stringProperties.mapValues { $0 as Any }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(event, forKey: .event)
        try container.encode(timestamp, forKey: .timestamp)
        
        // Encode properties as [String: String] for simplicity
        let stringProperties = properties.mapValues { "\($0)" }
        try container.encode(stringProperties, forKey: .properties)
    }
}

struct TelemetryConfig: Codable {
    let enabled: Bool
}

struct UsageAnalytics {
    let totalSessions: Int
    let totalCommands: Int
    let mostUsedCommands: [String: Int]
    let averageBuildTime: TimeInterval?
    let errorRate: Double
    let featureUsage: [String: Int]
}

// MARK: - Telemetry Command

struct TelemetryCommand: ParsableCommand, RunnableCommand {
    static let configuration = CommandConfiguration(
        commandName: "telemetry",
        abstract: "Manage telemetry and usage analytics"
    )
    
    @Argument(help: "Telemetry action (show, enable, disable, clear)")
    var action: String
    
    var timeout: Duration { .seconds(30) }
    
    func execute(bag: CancellationBag) async throws -> ExitCode {
        switch action {
        case "show":
            return try await showAnalytics()
        case "enable":
            await Telemetry.shared.setEnabled(true)
            return .success
        case "disable":
            await Telemetry.shared.setEnabled(false)
            return .success
        case "clear":
            await Telemetry.shared.clearData()
            return .success
        default:
            Logger.error("Unknown action: \(action)")
            return .failure
        }
    }
    
    private func showAnalytics() async throws -> ExitCode {
        let analytics = await Telemetry.shared.getAnalytics()
        
        Logger.section("📊 Usage Analytics")
        
        Logger.info("Total sessions: \(analytics.totalSessions)")
        Logger.info("Total commands: \(analytics.totalCommands)")
        
        if let avgBuildTime = analytics.averageBuildTime {
            Logger.info("Average build time: \(formatDuration(avgBuildTime))")
        }
        
        Logger.info("Error rate: \(String(format: "%.1f", analytics.errorRate * 100))%")
        
        if !analytics.mostUsedCommands.isEmpty {
            Logger.info("Most used commands:")
            let sortedCommands = analytics.mostUsedCommands.sorted { $0.value > $1.value }
            for (command, count) in sortedCommands.prefix(5) {
                Logger.bullet("\(command): \(count) times")
            }
        }
        
        if !analytics.featureUsage.isEmpty {
            Logger.info("Feature usage:")
            let sortedFeatures = analytics.featureUsage.sorted { $0.value > $1.value }
            for (feature, count) in sortedFeatures.prefix(5) {
                Logger.bullet("\(feature): \(count) times")
            }
        }
        
        Logger.info("Telemetry status: \(await Telemetry.shared.isTelemetryEnabled() ? "enabled" : "disabled")")
        
        return .success
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else if duration < 3600 {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(seconds)s"
        } else {
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        }
    }
}

// MARK: - Helper Functions

private func runProcessSync(_ executable: String, arguments: [String]) throws -> ProcessResult {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    
    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr
    
    try process.run()
    process.waitUntilExit()
    
    let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
    let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
    
    let stdoutString = String(data: stdoutData, encoding: .utf8) ?? ""
    let stderrString = String(data: stderrData, encoding: .utf8) ?? ""
    
    return ProcessResult(
        exitCode: process.terminationStatus,
        stdout: stdoutString,
        stderr: stderrString
    )
}
