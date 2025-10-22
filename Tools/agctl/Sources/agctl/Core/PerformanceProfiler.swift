import Foundation
import ArgumentParser

/// Performance profiling system for agctl operations
/// Tracks build times, identifies bottlenecks, and provides optimization suggestions
@MainActor
class PerformanceProfiler: @unchecked Sendable {
    static let shared = PerformanceProfiler()
    
    private var currentSession: ProfilingSession?
    private var historicalData: [ProfilingSession] = []
    private let dataDirectory: URL
    
    private init() {
        dataDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".agctl/profiling")
        
        // Ensure data directory exists
        try? FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        
        // Load historical data
        loadHistoricalData()
    }
    
    // MARK: - Session Management
    
    /// Start a new profiling session
    func startSession(operation: String, packageName: String? = nil) {
        currentSession = ProfilingSession(
            id: UUID().uuidString,
            operation: operation,
            packageName: packageName,
            startTime: Date(),
            events: []
        )
    }
    
    /// End the current profiling session
    func endSession() -> ProfilingSession? {
        guard var session = currentSession else { return nil }
        
        session.endTime = Date()
        session.duration = session.endTime!.timeIntervalSince(session.startTime)
        
        // Save the session
        saveSession(session)
        historicalData.append(session)
        
        currentSession = nil
        return session
    }
    
    /// Record an event during profiling
    func recordEvent(_ event: ProfilingEvent) {
        currentSession?.events.append(event)
    }
    
    // MARK: - Build Profiling
    
    /// Profile a build operation
    func profileBuild(packageName: String?, operation: @escaping () async throws -> ExitCode) async throws -> ExitCode {
        startSession(operation: "build", packageName: packageName)
        
        let startTime = Date()
        recordEvent(ProfilingEvent(name: "build_start", timestamp: startTime))
        
        do {
            let result = try await operation()
            
            let endTime = Date()
            recordEvent(ProfilingEvent(name: "build_success", timestamp: endTime))
            
            let duration = endTime.timeIntervalSince(startTime)
            recordEvent(ProfilingEvent(name: "build_duration", timestamp: endTime, data: ["duration": duration]))
            
            if let session = endSession() {
                analyzeBuildPerformance(session)
            }
            
            return result
            
        } catch {
            let endTime = Date()
            recordEvent(ProfilingEvent(name: "build_failure", timestamp: endTime))
            throw error
        }
    }
    
    /// Profile a test operation
    func profileTest(packageName: String?, operation: @escaping () async throws -> Void) async throws {
        startSession(operation: "test", packageName: packageName)
        
        let startTime = Date()
        recordEvent(ProfilingEvent(name: "test_start", timestamp: startTime))
        
        do {
            try await operation()
            
            let endTime = Date()
            recordEvent(ProfilingEvent(name: "test_success", timestamp: endTime))
            
        } catch {
            let endTime = Date()
            recordEvent(ProfilingEvent(name: "test_failure", timestamp: endTime))
            throw error
        }
        
        if let session = endSession() {
            analyzeTestPerformance(session)
        }
    }
    
    // MARK: - Analysis
    
    /// Analyze build performance and provide suggestions
    private func analyzeBuildPerformance(_ session: ProfilingSession) {
        guard let duration = session.duration else { return }
        
        Logger.section("📊 Build Performance Analysis")
        
        // Show duration
        Logger.info("Build duration: \(formatDuration(duration))")
        
        // Compare with historical data
        let similarBuilds = historicalData.filter { 
            $0.operation == "build" && 
            $0.packageName == session.packageName &&
            $0.id != session.id
        }
        
        if !similarBuilds.isEmpty {
            let avgDuration = similarBuilds.compactMap { $0.duration }.reduce(0, +) / Double(similarBuilds.count)
            let improvement = ((avgDuration - duration) / avgDuration) * 100
            
            if improvement > 10 {
                Logger.success("Build is \(String(format: "%.1f", improvement))% faster than average! 🚀")
            } else if improvement < -10 {
                Logger.warning("Build is \(String(format: "%.1f", abs(improvement)))% slower than average")
            }
        }
        
        // Provide optimization suggestions
        let suggestions = generateOptimizationSuggestions(session)
        if !suggestions.isEmpty {
            Logger.info("Optimization suggestions:")
            for suggestion in suggestions {
                Logger.bullet(suggestion)
            }
        }
        
        print("")
    }
    
    /// Analyze test performance
    private func analyzeTestPerformance(_ session: ProfilingSession) {
        guard let duration = session.duration else { return }
        
        Logger.section("🧪 Test Performance Analysis")
        Logger.info("Test duration: \(formatDuration(duration))")
        
        // Test-specific suggestions
        if duration > 60 {
            Logger.warning("Tests are taking longer than 1 minute")
            Logger.bullet("Consider running tests in parallel: agctl test --parallel")
            Logger.bullet("Check for slow or flaky tests")
        }
        
        print("")
    }
    
    /// Generate optimization suggestions based on performance data
    private func generateOptimizationSuggestions(_ session: ProfilingSession) -> [String] {
        var suggestions: [String] = []
        
        guard let duration = session.duration else { return suggestions }
        
        // Build time suggestions
        if duration > 300 { // 5 minutes
            suggestions.append("Build is taking over 5 minutes - consider incremental builds")
            suggestions.append("Check for unnecessary dependencies in Package.swift")
        }
        
        if duration > 120 { // 2 minutes
            suggestions.append("Try building with more parallel jobs: agctl build --parallel=8")
            suggestions.append("Consider using 'agctl build --incremental' for faster rebuilds")
        }
        
        // Package-specific suggestions
        if let packageName = session.packageName {
            let packageBuilds = historicalData.filter { 
                $0.operation == "build" && $0.packageName == packageName 
            }
            
            if packageBuilds.count > 5 {
                let avgDuration = packageBuilds.compactMap { $0.duration }.reduce(0, +) / Double(packageBuilds.count)
                
                if duration > avgDuration * 1.5 {
                    suggestions.append("\(packageName) is building slower than usual - check for recent changes")
                }
            }
        }
        
        return suggestions
    }
    
    // MARK: - Historical Analysis
    
    /// Get performance trends
    func getPerformanceTrends() -> PerformanceTrends {
        let buildSessions = historicalData.filter { $0.operation == "build" }
        let testSessions = historicalData.filter { $0.operation == "test" }
        
        return PerformanceTrends(
            totalBuilds: buildSessions.count,
            totalTests: testSessions.count,
            averageBuildTime: calculateAverageDuration(buildSessions),
            averageTestTime: calculateAverageDuration(testSessions),
            slowestBuild: findSlowestSession(buildSessions),
            slowestTest: findSlowestSession(testSessions),
            recentTrend: calculateRecentTrend(buildSessions)
        )
    }
    
    private func calculateAverageDuration(_ sessions: [ProfilingSession]) -> TimeInterval? {
        let durations = sessions.compactMap { $0.duration }
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }
    
    private func findSlowestSession(_ sessions: [ProfilingSession]) -> ProfilingSession? {
        return sessions.max { ($0.duration ?? 0) < ($1.duration ?? 0) }
    }
    
    private func calculateRecentTrend(_ sessions: [ProfilingSession]) -> PerformanceTrend {
        let sortedSessions = sessions.sorted { $0.startTime < $1.startTime }
        guard sortedSessions.count >= 2 else { return .stable }
        
        let recent = Array(sortedSessions.suffix(5))
        let older = Array(sortedSessions.prefix(max(1, sortedSessions.count - 5)))
        
        let recentAvg = calculateAverageDuration(recent) ?? 0
        let olderAvg = calculateAverageDuration(older) ?? 0
        
        let improvement = ((olderAvg - recentAvg) / olderAvg) * 100
        
        if improvement > 10 {
            return .improving
        } else if improvement < -10 {
            return .degrading
        } else {
            return .stable
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveSession(_ session: ProfilingSession) {
        let filename = "\(session.id).json"
        let fileURL = dataDirectory.appendingPathComponent(filename)
        
        do {
            let data = try JSONEncoder().encode(session)
            try data.write(to: fileURL)
        } catch {
            Logger.warning("Failed to save profiling data: \(error)")
        }
    }
    
    private func loadHistoricalData() {
        guard FileManager.default.fileExists(atPath: dataDirectory.path) else { return }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: dataDirectory.path)
            
            for file in files where file.hasSuffix(".json") {
                let fileURL = dataDirectory.appendingPathComponent(file)
                let data = try Data(contentsOf: fileURL)
                let session = try JSONDecoder().decode(ProfilingSession.self, from: data)
                historicalData.append(session)
            }
        } catch {
            Logger.warning("Failed to load historical profiling data: \(error)")
        }
    }
    
    // MARK: - Utility
    
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

// MARK: - Supporting Types

struct ProfilingSession: Codable, Sendable {
    let id: String
    let operation: String
    let packageName: String?
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval?
    var events: [ProfilingEvent]
}

struct ProfilingEvent: Codable, @unchecked Sendable {
    let name: String
    let timestamp: Date
    let data: [String: Any]
    
    init(name: String, timestamp: Date, data: [String: Any] = [:]) {
        self.name = name
        self.timestamp = timestamp
        self.data = data
    }
    
    // Custom coding for [String: Any]
    enum CodingKeys: String, CodingKey {
        case name, timestamp, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Decode data as [String: String] for simplicity
        let dataDict = try container.decodeIfPresent([String: String].self, forKey: .data) ?? [:]
        data = dataDict.mapValues { $0 as Any }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(timestamp, forKey: .timestamp)
        
        // Encode data as [String: String] for simplicity
        let stringData = data.mapValues { "\($0)" }
        try container.encode(stringData, forKey: .data)
    }
}

struct PerformanceTrends: Sendable {
    let totalBuilds: Int
    let totalTests: Int
    let averageBuildTime: TimeInterval?
    let averageTestTime: TimeInterval?
    let slowestBuild: ProfilingSession?
    let slowestTest: ProfilingSession?
    let recentTrend: PerformanceTrend
}

enum PerformanceTrend {
    case improving
    case stable
    case degrading
}

// MARK: - Profiling Command

struct ProfileCommand: ParsableCommand, RunnableCommand {
    static let configuration = CommandConfiguration(
        commandName: "profile",
        abstract: "Performance profiling and analysis"
    )
    
    @Argument(help: "Profile action (show, clear, analyze)")
    var action: String
    
    @Option(help: "Package name to analyze")
    var package: String?
    
    var timeout: Duration { .seconds(60) }
    
    func execute(bag: CancellationBag) async throws -> ExitCode {
        switch action {
        case "show":
            return try await showProfileData()
        case "clear":
            return try await clearProfileData()
        case "analyze":
            return try await analyzeProfileData()
        default:
            Logger.error("Unknown action: \(action)")
            return .failure
        }
    }
    
    private func showProfileData() async throws -> ExitCode {
        let trends = await PerformanceProfiler.shared.getPerformanceTrends()
        
        Logger.section("📊 Performance Profile")
        Logger.info("Total builds: \(trends.totalBuilds)")
        Logger.info("Total tests: \(trends.totalTests)")
        
        if let avgBuild = trends.averageBuildTime {
            Logger.info("Average build time: \(formatDuration(avgBuild))")
        }
        
        if let avgTest = trends.averageTestTime {
            Logger.info("Average test time: \(formatDuration(avgTest))")
        }
        
        if let slowest = trends.slowestBuild {
            Logger.info("Slowest build: \(slowest.packageName ?? "all packages") (\(formatDuration(slowest.duration ?? 0)))")
        }
        
        let trendEmoji = trends.recentTrend == .improving ? "📈" : 
                        trends.recentTrend == .degrading ? "📉" : "➡️"
        Logger.info("Recent trend: \(trendEmoji) \(trends.recentTrend)")
        
        return .success
    }
    
    private func clearProfileData() async throws -> ExitCode {
        let dataDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".agctl/profiling")
        
        try? FileManager.default.removeItem(at: dataDirectory)
        try? FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        
        Logger.success("Profile data cleared")
        return .success
    }
    
    private func analyzeProfileData() async throws -> ExitCode {
        let trends = await PerformanceProfiler.shared.getPerformanceTrends()
        
        Logger.section("🔍 Performance Analysis")
        
        // Analyze build performance
        if trends.totalBuilds > 0 {
            Logger.info("Build Performance:")
            
            if let avgBuild = trends.averageBuildTime {
                if avgBuild > 300 {
                    Logger.warning("  • Average build time is high (\(formatDuration(avgBuild)))")
                    Logger.bullet("Consider using incremental builds")
                    Logger.bullet("Check for unnecessary dependencies")
                } else if avgBuild < 60 {
                    Logger.success("  • Build times are excellent! 🚀")
                }
            }
            
            if let slowest = trends.slowestBuild, let duration = slowest.duration {
                if duration > 600 {
                    Logger.warning("  • Slowest build took \(formatDuration(duration))")
                    Logger.bullet("Investigate \(slowest.packageName ?? "all packages") build")
                }
            }
        }
        
        // Analyze test performance
        if trends.totalTests > 0 {
            Logger.info("Test Performance:")
            
            if let avgTest = trends.averageTestTime {
                if avgTest > 120 {
                    Logger.warning("  • Average test time is high (\(formatDuration(avgTest)))")
                    Logger.bullet("Consider running tests in parallel")
                    Logger.bullet("Check for slow or flaky tests")
                }
            }
        }
        
        // Trend analysis
        switch trends.recentTrend {
        case .improving:
            Logger.success("Performance is improving! 📈")
        case .degrading:
            Logger.warning("Performance is degrading 📉")
            Logger.bullet("Check recent changes for performance impact")
        case .stable:
            Logger.info("Performance is stable ➡️")
        }
        
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
