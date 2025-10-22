import Foundation

// MARK: - Process Result

/// Result of running a subprocess
struct ProcessResult: Sendable {
    let exitCode: Int32
    let stdout: String
    let stderr: String
    
    /// Whether the process succeeded (exit code 0)
    var isSuccess: Bool { exitCode == 0 }
    
    /// Combined output (stdout + stderr)
    var combinedOutput: String {
        [stdout, stderr].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}

// MARK: - Async Line Reader

/// Async reader that streams data from a FileHandle without blocking
actor AsyncLineReader {
    private let handle: FileHandle
    
    init(handle: FileHandle) {
        self.handle = handle
    }
    
    /// Read all data from the handle asynchronously
    func readAll() async -> String {
        // Read on background thread to avoid blocking
        await Task.detached {
            // readDataToEndOfFile blocks until EOF (when pipe closes)
            let data = self.handle.readDataToEndOfFile()
            return String(decoding: data, as: UTF8.self)
        }.value
    }
}

// MARK: - Async Process Runner

/// Run a subprocess with proper async/await support and no deadlock risks
///
/// This implementation:
/// - Reads stdout/stderr concurrently to prevent pipe buffer deadlocks
/// - Supports cancellation via CancellationBag
/// - Closes file handles properly in all cases
/// - Handles timeout via the caller's timeout wrapper
func runProcess(
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
    
    // Merge environment with current process environment
    var env = ProcessInfo.processInfo.environment
    for (key, value) in environment {
        env[key] = value
    }
    process.environment = env
    
    if let workingDirectory {
        process.currentDirectoryURL = workingDirectory
    }
    
    // Create pipes for stdout and stderr
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    
    // Create readers before starting the process
    let stdoutReader = AsyncLineReader(handle: stdoutPipe.fileHandleForReading)
    let stderrReader = AsyncLineReader(handle: stderrPipe.fileHandleForReading)
    
    // Start the process
    try process.run()
    
    // Register cancellation handler
    bag.onCancel { [weak process] in
        process?.terminate()
    }
    
    // Read both streams concurrently to prevent deadlocks
    async let stdoutText = stdoutReader.readAll()
    async let stderrText = stderrReader.readAll()
    
    // Wait for process to complete with cancellation support
    await withTaskCancellationHandler {
        // Wait for the process to exit
        process.waitUntilExit()
    } onCancel: {
        process.terminate()
    }
    
    // Close file handles explicitly after process exits
    // This signals EOF to the readers
    defer {
        try? stdoutPipe.fileHandleForReading.close()
        try? stderrPipe.fileHandleForReading.close()
        try? stdoutPipe.fileHandleForWriting.close()
        try? stderrPipe.fileHandleForWriting.close()
    }
    
    // Collect results
    let stdout = await stdoutText
    let stderr = await stderrText
    
    return ProcessResult(
        exitCode: process.terminationStatus,
        stdout: stdout,
        stderr: stderr
    )
}

// MARK: - Convenience Overloads

/// Run a shell command (bash -c)
func runShellCommand(
    _ command: String,
    workingDirectory: URL? = nil,
    bag: CancellationBag
) async throws -> ProcessResult {
    try await runProcess(
        "/bin/bash",
        arguments: ["-c", command],
        workingDirectory: workingDirectory,
        bag: bag
    )
}

/// Run a command with swift (e.g., swift build, swift test)
func runSwift(
    arguments: [String],
    workingDirectory: URL? = nil,
    bag: CancellationBag
) async throws -> ProcessResult {
    try await runProcess(
        "/usr/bin/xcrun",
        arguments: ["swift"] + arguments,
        workingDirectory: workingDirectory,
        bag: bag
    )
}

/// Run a command and throw if it fails
@discardableResult
func runProcessOrThrow(
    _ executable: String,
    arguments: [String] = [],
    environment: [String: String] = [:],
    workingDirectory: URL? = nil,
    bag: CancellationBag
) async throws -> ProcessResult {
    let result = try await runProcess(
        executable,
        arguments: arguments,
        environment: environment,
        workingDirectory: workingDirectory,
        bag: bag
    )
    
    guard result.isSuccess else {
        throw ProcessError(
            executable: executable,
            arguments: arguments,
            result: result
        )
    }
    
    return result
}

// MARK: - Process Error

struct ProcessError: LocalizedError {
    let executable: String
    let arguments: [String]
    let result: ProcessResult
    
    var errorDescription: String? {
        let command = ([executable] + arguments).joined(separator: " ")
        var message = "Command failed (exit \(result.exitCode)): \(command)"
        
        if !result.stderr.isEmpty {
            message += "\n\(result.stderr)"
        }
        
        return message
    }
}


