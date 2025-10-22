import Foundation

/// Execute shell commands with guaranteed completion
enum Shell {
    struct CommandError: LocalizedError {
        let command: String
        let exitCode: Int32
        let output: String
        
        var errorDescription: String? {
            "Command failed with exit code \(exitCode): \(command)\n\(output)"
        }
    }
    
    /// Run a shell command and return its output
    /// - Parameters:
    ///   - command: The command to execute
    ///   - path: Optional working directory
    /// - Returns: The command's stdout output
    @discardableResult
    static func run(_ command: String, at path: String? = nil, captureStderr: Bool = false) throws -> String {
        // Use a simpler approach with bash directly instead of perl wrapper
        let workingDir = path ?? FileManager.default.currentDirectoryPath
        let fullCommand = "cd '\(workingDir)' && \(command)"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", fullCommand]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = captureStderr ? errorPipe : FileHandle.standardError
        
        try process.run()
        process.waitUntilExit()
        
        // Read output and close file handles to prevent hanging
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        outputPipe.fileHandleForReading.closeFile()
        
        if process.terminationStatus != 0 {
            // Only read from errorPipe if we actually connected it to the process
            let errorOutput: String
            if captureStderr {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                errorPipe.fileHandleForReading.closeFile()
            } else {
                errorOutput = ""
            }
            throw CommandError(
                command: command,
                exitCode: process.terminationStatus,
                output: output + errorOutput
            )
        }
        
        // Close error pipe even on success if it was used
        if captureStderr {
            errorPipe.fileHandleForReading.closeFile()
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check if a binary exists in PATH
    /// - Parameter binary: The binary name to search for
    /// - Returns: The full path to the binary, or nil if not found
    static func which(_ binary: String) -> String? {
        guard let result = try? run("which \(binary)", captureStderr: true),
              !result.isEmpty else {
            return nil
        }
        return result
    }
    
    /// Run a command and stream output in real-time
    static func runWithLiveOutput(_ command: String, at path: String? = nil) throws {
        // Use a simpler approach with bash directly
        let workingDir = path ?? FileManager.default.currentDirectoryPath
        let fullCommand = "cd '\(workingDir)' && \(command)"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", fullCommand]
        
        // Inherit stdout and stderr for real-time output
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw CommandError(
                command: command,
                exitCode: process.terminationStatus,
                output: ""
            )
        }
    }
}
