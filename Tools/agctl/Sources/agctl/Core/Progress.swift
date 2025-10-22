import Foundation

/// Progress indicator for long-running operations
final class ProgressIndicator: @unchecked Sendable {
    private let message: String
    private var isRunning = false
    private var thread: Thread?
    private let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    private var frameIndex = 0
    private var startTime: Date?
    
    init(message: String) {
        self.message = message
    }
    
    /// Start the progress indicator
    func start() {
        guard !isRunning else { return }
        isRunning = true
        startTime = Date()
        
        // Hide cursor
        print("\u{001B}[?25l", terminator: "")
        fflush(stdout)
        
        thread = Thread { [weak self] in
            while self?.isRunning == true {
                self?.render()
                Thread.sleep(forTimeInterval: 0.08)
            }
        }
        thread?.start()
    }
    
    /// Stop the progress indicator
    func stop(success: Bool = true, finalMessage: String? = nil) {
        guard isRunning else { return }
        isRunning = false
        
        // Wait for thread to actually finish before proceeding
        // This prevents the thread from keeping the process alive
        if let thread = thread, !thread.isCancelled {
            thread.cancel()
            // Give the thread a moment to exit the while loop
            Thread.sleep(forTimeInterval: 0.1)
        }
        thread = nil
        
        // Clear line
        print("\r\u{001B}[K", terminator: "")
        
        // Show cursor
        print("\u{001B}[?25h", terminator: "")
        
        if let final = finalMessage {
            let icon = success ? "✅" : "❌"
            if let start = startTime {
                let duration = Date().timeIntervalSince(start)
                print("\(icon) \(final) (\(String(format: "%.1fs", duration)))")
            } else {
                print("\(icon) \(final)")
            }
        }
        
        fflush(stdout)
    }
    
    private func render() {
        let frame = frames[frameIndex]
        frameIndex = (frameIndex + 1) % frames.count
        
        var output = "\r\(frame) \(message)"
        
        if let start = startTime {
            let elapsed = Date().timeIntervalSince(start)
            output += " (\(String(format: "%.1fs", elapsed)))"
        }
        
        print(output, terminator: "")
        fflush(stdout)
    }
}

/// Execute a closure with a progress indicator
func withProgress<T>(
    _ message: String,
    successMessage: String? = nil,
    failureMessage: String? = nil,
    operation: () throws -> T
) rethrows -> T {
    let progress = ProgressIndicator(message: message)
    progress.start()
    
    var success = false
    var finalMessage = failureMessage ?? "Failed"
    
    defer {
        // Ensure progress is always stopped
        progress.stop(success: success, finalMessage: finalMessage)
    }
    
    do {
        let result = try operation()
        success = true
        finalMessage = successMessage ?? "Success"
        return result
    } catch {
        // Progress will be stopped in defer block with failure status
        throw error
    }
}

/// Progress bar for operations with known progress
class ProgressBar {
    private let total: Int
    private var current: Int = 0
    private let width: Int = 40
    private let message: String
    private var startTime: Date?
    
    init(total: Int, message: String) {
        self.total = total
        self.message = message
        self.startTime = Date()
    }
    
    func update(current: Int, itemMessage: String? = nil) {
        self.current = current
        render(itemMessage: itemMessage)
    }
    
    func increment(itemMessage: String? = nil) {
        current += 1
        render(itemMessage: itemMessage)
    }
    
    func complete(finalMessage: String? = nil) {
        current = total
        render(itemMessage: nil)
        print() // New line
        
        if let final = finalMessage {
            if let start = startTime {
                let duration = Date().timeIntervalSince(start)
                Logger.success("\(final) (\(String(format: "%.1fs", duration)))")
            } else {
                Logger.success(final)
            }
        }
    }
    
    private func render(itemMessage: String?) {
        let percentage = Double(current) / Double(total)
        let filled = Int(percentage * Double(width))
        let empty = width - filled
        
        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
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

/// Time estimation for long operations
struct TimeEstimator {
    private let startTime: Date
    private let totalItems: Int
    
    init(totalItems: Int) {
        self.startTime = Date()
        self.totalItems = totalItems
    }
    
    func estimatedTimeRemaining(completed: Int) -> TimeInterval? {
        guard completed > 0 else { return nil }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let rate = Double(completed) / elapsed
        let remaining = Double(totalItems - completed)
        
        return remaining / rate
    }
    
    func formatTimeRemaining(completed: Int) -> String? {
        guard let remaining = estimatedTimeRemaining(completed: completed) else {
            return nil
        }
        
        if remaining < 60 {
            return String(format: "~%.0fs remaining", remaining)
        } else if remaining < 3600 {
            let minutes = remaining / 60
            return String(format: "~%.0fm remaining", minutes)
        } else {
            let hours = remaining / 3600
            return String(format: "~%.1fh remaining", hours)
        }
    }
}

