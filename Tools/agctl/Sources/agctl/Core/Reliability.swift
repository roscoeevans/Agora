import Foundation
import ArgumentParser

// MARK: - Cancellation Infrastructure

/// Manages cancellation callbacks for coordinated cleanup
final class CancellationBag: @unchecked Sendable {
    private let lock = NSLock()
    private var actions: [@Sendable () -> Void] = []
    private var isCancelled = false
    
    /// Register a cleanup action to be called on cancellation
    func onCancel(_ action: @escaping @Sendable () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        
        if isCancelled {
            // Already cancelled, execute immediately
            action()
        } else {
            actions.append(action)
        }
    }
    
    /// Cancel all registered operations
    func cancelAll() {
        lock.lock()
        let actionsToExecute = actions
        actions = []
        isCancelled = true
        lock.unlock()
        
        // Execute outside the lock to prevent deadlocks
        for action in actionsToExecute {
            action()
        }
    }
}

// MARK: - Timeout Infrastructure

/// Error thrown when a command exceeds its timeout
struct TimeoutError: LocalizedError {
    let duration: Duration
    
    var errorDescription: String? {
        "Command timed out after \(formatDuration(duration))"
    }
    
    private func formatDuration(_ d: Duration) -> String {
        let seconds = Double(d.components.seconds) + Double(d.components.attoseconds) / 1e18
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m"
        } else {
            return String(format: "%.1fh", seconds / 3600)
        }
    }
}

/// Execute an async operation with a timeout
func withTimeout<T: Sendable>(
    _ duration: Duration,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        // Add the actual operation
        group.addTask {
            try await operation()
        }
        
        // Add the timeout watchdog
        group.addTask {
            try await Task.sleep(for: duration)
            throw TimeoutError(duration: duration)
        }
        
        // Wait for the first to complete
        guard let result = try await group.next() else {
            throw TimeoutError(duration: duration)
        }
        
        // Cancel the loser
        group.cancelAll()
        
        return result
    }
}

// MARK: - Signal Handling

/// Global signal handler (must be global for C interop)
nonisolated(unsafe) private var globalSignalHandler: (@Sendable () -> Void)?

/// Traps Unix signals (SIGINT, SIGTERM) for graceful shutdown
enum SignalTrap {
    enum Signal: Int32 {
        case int = 2   // SIGINT (Ctrl-C)
        case term = 15 // SIGTERM
    }
    
    /// Install signal handlers
    static func install(_ signals: [Signal], handler: @escaping @Sendable () -> Void) {
        globalSignalHandler = handler
        
        for sig in signals {
            signal(sig.rawValue, signalHandler)
        }
    }
}

/// C-compatible signal handler
private func signalHandler(_ signal: Int32) {
    globalSignalHandler?()
}

// MARK: - Command Protocol

/// Commands that support guarded execution with timeouts and cancellation
protocol RunnableCommand: Sendable {
    /// Execute the command with cancellation support
    /// - Parameter bag: Cancellation bag for cleanup coordination
    /// - Returns: Exit code indicating success or failure
    func execute(bag: CancellationBag) async throws -> ExitCode
    
    /// Maximum time this command should run before being killed
    var timeout: Duration { get }
}

extension RunnableCommand {
    /// Default timeout: 10 minutes for most commands
    var timeout: Duration { .seconds(600) }
}

// MARK: - Guarded Execution

extension RunnableCommand {
    /// Execute with full reliability guards: timeout, signal handling, cleanup
    func runWithGuards() async -> ExitCode {
        let bag = CancellationBag()
        
        // Install signal handlers for graceful shutdown
        SignalTrap.install([.int, .term]) {
            bag.cancelAll()
        }
        
        do {
            // Run with timeout watchdog
            return try await withTimeout(timeout) { @Sendable in
                do {
                    return try await execute(bag: bag)
                } catch {
                    // Command execution error
                    Logger.error("\(error)")
                    return .failure
                }
            }
        } catch is TimeoutError {
            Logger.error("Command timed out")
            bag.cancelAll()
            return .failure
        } catch {
            Logger.error("Unexpected error: \(error)")
            return .failure
        }
    }
}

// MARK: - ExitCode Extension

extension ExitCode {
    /// Standard success exit code
    static let success = ExitCode(0)
    
    /// Standard failure exit code
    static let failure = ExitCode(1)
}

