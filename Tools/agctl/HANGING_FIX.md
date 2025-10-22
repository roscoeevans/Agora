# agctl Hanging Issue Fix

## Problem
The `agctl` CLI tool was experiencing hanging behavior where commands would complete (successfully OR with errors) but not return control to the shell, requiring `^C` to terminate.

**Critical symptom:** `agctl build --verbose` would exit cleanly in 4 seconds, but `agctl build` (non-verbose) would hang indefinitely.

## Root Causes

### 1. **Reading from Unconnected Pipe** (Critical - The Main Culprit)
In `Shell.run()`, when `captureStderr: Bool = false` (the default), the `errorPipe` was created but never connected to the process. On build failure, the code would try to read from this unconnected pipe, **hanging forever** waiting for data that would never come:

```swift
// errorPipe created but not connected when captureStderr is false
process.standardError = captureStderr ? errorPipe : FileHandle.standardError

// Later, on error:
let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()  // ❌ HANGS!
```

### 2. **Missing File Handle Closures** (Important)
In `Shell.swift`, the `Pipe` file handles were never explicitly closed after reading data. This is a classic cause of CLI tools hanging because:
- `Pipe.fileHandleForReading` stays open indefinitely
- The process waits for EOF that never comes
- Even after `process.waitUntilExit()`, dangling file descriptors prevent clean termination

### 3. **No Explicit Exit Handling** (Nice to Have)
The main command relied on `swift-argument-parser`'s default behavior, which doesn't explicitly call `exit()`. This can leave the process alive if there are any:
- Dangling async tasks
- Background RunLoop activity
- Unclosed resources

## Solutions Implemented

### 1. Fixed Unconnected Pipe Read (Critical Fix)

**Before:**
```swift
let errorPipe = Pipe()
process.standardError = captureStderr ? errorPipe : FileHandle.standardError

if process.terminationStatus != 0 {
    // ❌ Always reads from errorPipe, even when not connected!
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()  // HANGS!
    let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
    errorPipe.fileHandleForReading.closeFile()
    throw CommandError(...)
}
```

**After:**
```swift
let errorPipe = Pipe()
process.standardError = captureStderr ? errorPipe : FileHandle.standardError

if process.terminationStatus != 0 {
    // ✅ Only read from errorPipe if it's actually connected
    let errorOutput: String
    if captureStderr {
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        errorOutput = String(data: errorData, encoding: .utf8) ?? ""
        errorPipe.fileHandleForReading.closeFile()
    } else {
        errorOutput = ""
    }
    throw CommandError(...)
}
```

**Key Change:** Only attempt to read from `errorPipe` if `captureStderr` is `true` and the pipe is actually connected to the process.

### 2. Fixed Shell.swift Pipe Handling

**Before:**
```swift
let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
let output = String(data: outputData, encoding: .utf8) ?? ""

if process.terminationStatus != 0 {
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
    // ❌ Pipes never closed!
    throw CommandError(...)
}

return output.trimmingCharacters(in: .whitespacesAndNewlines)
```

**After:**
```swift
let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
let output = String(data: outputData, encoding: .utf8) ?? ""
outputPipe.fileHandleForReading.closeFile() // ✅ Always close stdout pipe

if process.terminationStatus != 0 {
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
    errorPipe.fileHandleForReading.closeFile() // ✅ Close stderr on error
    throw CommandError(...)
}

// ✅ Close error pipe even on success if it was used
if captureStderr {
    errorPipe.fileHandleForReading.closeFile()
}

return output.trimmingCharacters(in: .whitespacesAndNewlines)
```

**Key Changes:**
- Always close `outputPipe.fileHandleForReading` after reading
- Close `errorPipe.fileHandleForReading` in both error and success paths
- Ensures all file descriptors are properly released

### 3. Added Explicit Exit Handling

**Before:**
```swift
@main
struct AGCTLCommand: ParsableCommand {
    static let configuration = CommandConfiguration(...)
    // ❌ No explicit exit - relies on default ArgumentParser behavior
}
```

**After:**
```swift
@main
struct AGCTLCommand: ParsableCommand {
    static let configuration = CommandConfiguration(...)
    
    /// Custom main() to ensure proper exit handling
    static func main() {
        do {
            var command = try parseAsRoot()
            try command.run()
            // ✅ Explicitly exit with success to prevent hanging
            Foundation.exit(EXIT_SUCCESS)
        } catch {
            // ✅ Handle errors and exit cleanly
            Self.exit(withError: error)
        }
    }
}
```

**Key Changes:**
- Override `main()` to control process termination
- Explicit `Foundation.exit(EXIT_SUCCESS)` on success
- Use `Self.exit(withError:)` for error handling (maintains ArgumentParser's error formatting)
- Ensures process always terminates cleanly

## Modern CLI Tool Best Practices (2025)

### ✅ DO:
1. **Always close file handles** - Call `.closeFile()` on all `Pipe` file handles after use
2. **Explicitly exit** - Call `exit(EXIT_SUCCESS)` or `exit(EXIT_FAILURE)` at the end of execution
3. **Use structured concurrency** - Prefer `await` over `Task.detached`
4. **Clean error handling** - Wrap everything in proper error handlers
5. **Platform alignment** - Use modern baseline versions (macOS 15+, iOS 18+)

### ❌ DON'T:
1. **Leave pipes open** - Dangling file handles are the #1 cause of hanging
2. **Rely on implicit exit** - Always control termination explicitly
3. **Use detached tasks carelessly** - They can keep the process alive
4. **Forget error paths** - Close resources in both success and failure cases
5. **Mix old/new patterns** - Stick to modern Swift 6 concurrency

## Testing

All commands tested and confirmed working without hanging:

```bash
# Help command
agctl --help
✅ Completes instantly

# Config command (no subprocesses)
agctl config show
✅ Completes instantly

# Validate command (uses Shell.run with Process/Pipe)
agctl validate platforms
✅ Completes instantly (0.1s)

# Build command - VERBOSE MODE (already worked)
agctl build AuthFeature --verbose
✅ Exits cleanly in 4 seconds (with build error)

# Build command - NON-VERBOSE MODE (was hanging, now fixed!)
agctl build AuthFeature
✅ Exits cleanly in 2.8 seconds (with build error)
❌ Build failed
❌ Error: Command failed with exit code 1: swift build -c debug
✅ NO HANGING! Returns to shell immediately!
```

### Before vs After

**Before Fix:**
- `agctl build AuthFeature --verbose` → ✅ Exits in 4s
- `agctl build AuthFeature` → ❌ **HANGS FOREVER**

**After Fix:**
- `agctl build AuthFeature --verbose` → ✅ Exits in 4s
- `agctl build AuthFeature` → ✅ **EXITS IN 2.8s**

## Related Files
- `Sources/agctl/Core/Shell.swift` - Fixed pipe handling
- `Sources/agctl/AGCTLCommand.swift` - Added explicit exit handling
- `Package.swift` - Already using modern platform versions ✅

## Platform Requirements
- **Swift Tools:** 6.2
- **macOS:** 15.0+
- **Dependencies:** swift-argument-parser 1.5.0+

## References
- [Swift Argument Parser Docs](https://github.com/apple/swift-argument-parser)
- [Process and Pipe Best Practices](https://developer.apple.com/documentation/foundation/process)
- Modern CLI Tool Patterns (2025)

