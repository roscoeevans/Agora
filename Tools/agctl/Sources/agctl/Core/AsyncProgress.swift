import Foundation

// MARK: - Async Spinner

/// Async spinner that guarantees cleanup and never outlives its task
actor AsyncSpinner {
    private let message: String
    private var task: Task<Void, Never>?
    private let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    private var frameIndex = 0
    private let startTime: ContinuousClock.Instant
    
    init(message: String) {
        self.message = message
        self.startTime = ContinuousClock.now
    }
    
    /// Start the spinner animation
    func start() {
        // Hide cursor
        print("\u{001B}[?25l", terminator: "")
        fflush(stdout)
        
        task = Task { [weak self] in
            while !Task.isCancelled {
                await self?.render()
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }
    
    /// Stop the spinner and show final message
    func stop(success: Bool = true, finalMessage: String? = nil) {
        // Cancel and wait for the animation task
        task?.cancel()
        task = nil
        
        // Clear line
        print("\r\u{001B}[K", terminator: "")
        
        // Show cursor
        print("\u{001B}[?25h", terminator: "")
        
        if let final = finalMessage {
            let icon = success ? "✅" : "❌"
            let duration = ContinuousClock.now - startTime
            let seconds = Double(duration.components.seconds) + 
                         Double(duration.components.attoseconds) / 1e18
            print("\(icon) \(final) (\(String(format: "%.1fs", seconds)))")
        }
        
        fflush(stdout)
    }
    
    private func render() {
        let frame = frames[frameIndex]
        frameIndex = (frameIndex + 1) % frames.count
        
        let duration = ContinuousClock.now - startTime
        let seconds = Double(duration.components.seconds) + 
                     Double(duration.components.attoseconds) / 1e18
        
        let output = "\r\(frame) \(message) (\(String(format: "%.1fs", seconds)))"
        print(output, terminator: "")
        fflush(stdout)
    }
}

// MARK: - Spinner Helper

/// Execute an async operation with a spinner that guarantees cleanup
func withSpinner<T>(
    _ message: String,
    successMessage: String? = nil,
    failureMessage: String? = nil,
    operation: @Sendable () async throws -> T
) async throws -> T {
    let spinner = AsyncSpinner(message: message)
    await spinner.start()
    
    do {
        let result = try await operation()
        await spinner.stop(success: true, finalMessage: successMessage ?? message)
        return result
    } catch {
        await spinner.stop(success: false, finalMessage: failureMessage ?? message)
        throw error
    }
}

// MARK: - Async Progress Bar

/// Progress bar for operations with known item count
actor AsyncProgressBar {
    private let total: Int
    private var current: Int = 0
    private let width: Int = 40
    private let message: String
    private let startTime: ContinuousClock.Instant
    
    init(total: Int, message: String) {
        self.total = total
        self.message = message
        self.startTime = ContinuousClock.now
    }
    
    /// Update progress to a specific value
    func update(current: Int, itemMessage: String? = nil) {
        self.current = current
        render(itemMessage: itemMessage)
    }
    
    /// Increment progress by one
    func increment(itemMessage: String? = nil) {
        current += 1
        render(itemMessage: itemMessage)
    }
    
    /// Mark progress as complete
    func complete(finalMessage: String? = nil) {
        current = total
        render(itemMessage: nil)
        print() // New line
        
        if let final = finalMessage {
            let duration = ContinuousClock.now - startTime
            let seconds = Double(duration.components.seconds) + 
                         Double(duration.components.attoseconds) / 1e18
            Logger.success("\(final) (\(String(format: "%.1fs", seconds)))")
        }
    }
    
    private func render(itemMessage: String?) {
        let percentage = Double(current) / Double(total)
        let filled = Int(percentage * Double(width))
        let empty = width - filled
        
        let bar = String(repeating: "█", count: filled) + 
                 String(repeating: "░", count: empty)
        let percentText = String(format: "%3.0f%%", percentage * 100)
        
        var output = "\r\(message): [\(bar)] \(percentText) (\(current)/\(total))"
        
        if let item = itemMessage {
            output += " - \(item)"
        }
        
        // Pad to clear previous longer messages
        output += String(repeating: " ", count: 20)
        
        print(output, terminator: "")
        fflush(stdout)
    }
}

// MARK: - Progress Bar Helper

/// Execute a sequence of operations with a progress bar
func withProgressBar<T>(
    total: Int,
    message: String,
    finalMessage: String,
    operation: @Sendable (AsyncProgressBar) async throws -> T
) async throws -> T {
    let progressBar = AsyncProgressBar(total: total, message: message)
    
    do {
        let result = try await operation(progressBar)
        await progressBar.complete(finalMessage: finalMessage)
        return result
    } catch {
        await progressBar.complete(finalMessage: "Failed")
        throw error
    }
}

// MARK: - Stream Live Output

/// Stream output from a process in real-time with cancellation support
actor OutputStreamer {
    private var lines: [String] = []
    
    func appendLine(_ line: String) {
        lines.append(line)
        print(line)
        fflush(stdout)
    }
    
    func getAllLines() -> [String] {
        lines
    }
}

/// Run a process and stream its output live
func runProcessWithLiveOutput(
    _ executable: String,
    arguments: [String] = [],
    environment: [String: String] = [:],
    workingDirectory: URL? = nil,
    bag: CancellationBag
) async throws -> ProcessResult {
    let process = Process()
    
    // Configure process
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    
    // Merge environment
    var env = ProcessInfo.processInfo.environment
    for (key, value) in environment {
        env[key] = value
    }
    process.environment = env
    
    if let workingDirectory {
        process.currentDirectoryURL = workingDirectory
    }
    
    // For live output, we inherit stdout/stderr
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError
    
    // Start the process
    try process.run()
    
    // Register cancellation
    bag.onCancel { [weak process] in
        process?.terminate()
    }
    
    // Wait with cancellation support
    await withTaskCancellationHandler {
        process.waitUntilExit()
    } onCancel: {
        process.terminate()
    }
    
    return ProcessResult(
        exitCode: process.terminationStatus,
        stdout: "",  // Already streamed to stdout
        stderr: ""   // Already streamed to stderr
    )
}

