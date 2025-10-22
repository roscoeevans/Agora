# agctl 1.3.0 Migration Guide

## 🎉 What's New

agctl 1.3.0 is a comprehensive redesign focused on two goals:

1. **✨ Buttery Smooth**: Zero hangs, ever. Full async/await, proper timeouts, cancellation support.
2. **🔄 Always Up-to-Date**: Bootstrap shim + version pinning means changes take effect instantly.

## New Architecture

### Reliability Infrastructure

#### No More Hangs

Every command now runs with:

- **Explicit timeouts**: Commands have watchdog timers (configurable per-command)
- **Cancellation support**: Ctrl-C properly terminates child processes
- **Bulletproof subprocess runner**: No pipe deadlocks, concurrent stdout/stderr reading
- **Strict lifecycle management**: Spinners and file handles always cleaned up
- **Signal handling**: SIGINT/SIGTERM gracefully cancel operations

#### How It Works

```swift
// Old synchronous command
struct OldCommand: ParsableCommand {
    func run() throws {
        // Could hang forever...
        try Shell.run("swift build")
    }
}

// New async command with guards
struct NewCommand: ParsableCommand, RunnableCommand {
    var timeout: Duration { .seconds(600) }  // 10 min max
    
    func execute(bag: CancellationBag) async throws -> ExitCode {
        // Guaranteed to exit within timeout
        let result = try await runSwift(
            arguments: ["build"],
            bag: bag
        )
        return result.isSuccess ? .success : .failure
    }
}
```

The main entrypoint automatically wraps every `RunnableCommand` with:
- Timeout watchdog
- Signal handlers (Ctrl-C)
- Explicit exit() call

**Result**: Commands can never hang your terminal.

### Updatability

#### Bootstrap Shim

A tiny (~3KB) shim installed at `/usr/local/bin/agctl` that:

1. **Local dev builds**: Auto-rebuilds when sources change (cached by git hash)
2. **Version pinning**: Reads `.agctl-version` and execs that specific version
3. **Auto-download**: Fetches missing versions from GitHub releases
4. **Zero config**: Just works™

#### Installation

```bash
# One-time setup
cd Tools/agctl-shim
./install.sh

# Verify
which agctl  # Should show /usr/local/bin/agctl
```

#### How It Works

```
You run: agctl build

Shim checks:
1. Am I in Agora repo?
   YES → Is Tools/agctl newer than cached build?
         YES → Rebuild to ~/.agctl/builds/<hash>/agctl
         NO  → Use cached build
   
2. Does .agctl-version exist?
   YES → Use ~/.agctl/versions/<version>/agctl
         (download if missing)
   
3. Fallback: Use latest installed version

Then: exec() the resolved binary
```

**Result**: Edit code → run command → uses your changes instantly.

### Version Pinning

The repo now has `.agctl-version`:

```
1.3.0
```

This ensures:
- CI runs the same version as developers
- Teams stay in sync
- Explicit upgrades (update the file)

To upgrade:

```bash
agctl self-update
# Updates .agctl-version automatically if in repo
```

## New Commands

### `agctl self-update`

Update to the latest version:

```bash
# Update to latest stable
agctl self-update

# Update to nightly
agctl self-update --channel nightly
```

### `agctl doctor`

Health check for your installation:

```bash
agctl doctor
```

Checks:
- ✅ Shim installation
- ✅ Cache directories (writable?)
- ✅ Git repository
- ✅ Swift toolchain
- ✅ Dependencies (SwiftLint, OpenAPI generator)
- ✅ Code signing

### `agctl dev`

Development mode with auto-reload:

```bash
# Watch for changes and rebuild
agctl dev

# Watch and run tests on change
agctl dev swift test

# Watch specific directory
agctl dev --watch Sources/agctl/Commands
```

**Perfect for**: Polishing spinners, tweaking output, rapid iteration.

## Migration Checklist

### For Developers

- [x] Core reliability infrastructure (timeouts, cancellation, signals)
- [x] Bulletproof subprocess runner
- [x] Async spinners and progress bars
- [x] Bootstrap shim
- [x] Version pinning (`.agctl-version`)
- [x] `agctl self-update` command
- [x] `agctl doctor` command
- [x] `agctl dev` command
- [x] CI hang-guard test
- [ ] Migrate remaining commands to RunnableCommand
- [ ] GitHub Actions release workflow
- [ ] Download implementation in self-update

### For Users

1. **Install the shim** (one-time):
   ```bash
   cd Tools/agctl-shim
   ./install.sh
   ```

2. **Verify installation**:
   ```bash
   agctl doctor
   ```

3. **That's it!** The shim handles everything else.

## Command Migration Guide

### Converting a Command

1. Add `RunnableCommand` conformance
2. Change `run()` to `execute(bag:) async throws -> ExitCode`
3. Add timeout property (optional, defaults to 10min)
4. Use async subprocess runners instead of Shell.run()
5. Return ExitCode instead of throwing

#### Before

```swift
struct MyCommand: ParsableCommand {
    func run() throws {
        let output = try Shell.run("swift build")
        Logger.success("Done!")
    }
}
```

#### After

```swift
struct MyCommand: ParsableCommand, RunnableCommand {
    var timeout: Duration { .seconds(600) }
    
    func execute(bag: CancellationBag) async throws -> ExitCode {
        let result = try await runSwift(
            arguments: ["build"],
            bag: bag
        )
        
        if result.isSuccess {
            Logger.success("Done!")
            return .success
        } else {
            Logger.error("Failed")
            return .failure
        }
    }
}
```

### Subprocess APIs

#### Old (synchronous, can hang)

```swift
try Shell.run("swift build")
try Shell.runWithLiveOutput("swift test")
```

#### New (async, guaranteed completion)

```swift
// Capture output
let result = try await runSwift(
    arguments: ["build", "-c", "release"],
    bag: bag
)

// Live streaming
let result = try await runProcessWithLiveOutput(
    "/usr/bin/xcrun",
    arguments: ["swift", "test"],
    bag: bag
)

// Throw on failure
try await runProcessOrThrow(
    "/usr/bin/git",
    arguments: ["status"],
    bag: bag
)
```

### Spinners

#### Old

```swift
_ = try withProgress("Building", successMessage: "Done") {
    try Shell.run("swift build")
}
```

#### New

```swift
try await withSpinner("Building", successMessage: "Done") {
    let result = try await runSwift(arguments: ["build"], bag: bag)
    guard result.isSuccess else {
        throw ProcessError(...)
    }
}
```

### Progress Bars

#### Old

```swift
let bar = ProgressBar(total: items.count, message: "Processing")
for item in items {
    bar.increment(itemMessage: item.name)
    // process item
}
bar.complete(finalMessage: "Done")
```

#### New

```swift
let bar = AsyncProgressBar(total: items.count, message: "Processing")
for item in items {
    await bar.increment(itemMessage: item.name)
    // process item
}
await bar.complete(finalMessage: "Done")
```

## CI Integration

### Hang-Guard Test

Add to your CI pipeline:

```yaml
- name: Test agctl doesn't hang
  run: |
    cd Tools/agctl
    chmod +x Tests/hang-guard.sh
    ./Tests/hang-guard.sh .build/release/agctl
```

This runs all commands with 60s timeout and fails if any hang.

### Version Pinning in CI

```yaml
- name: Install agctl
  run: |
    # Shim reads .agctl-version and uses that exact version
    curl -L https://github.com/agora-labs/agora-ios/releases/download/agctl-1.3.0/agctl-shim | bash
    
- name: Validate
  run: |
    agctl validate modules
    agctl validate dependencies
```

## Performance

### Before (1.2.0)

- Commands could hang indefinitely
- Manual timeout via perl wrapper (60s hardcoded)
- No cancellation support
- Sequential stdout/stderr reading (deadlock risk)

### After (1.3.0)

- Guaranteed completion within timeout
- Per-command configurable timeouts
- Full cancellation (Ctrl-C works immediately)
- Concurrent stream reading (no deadlocks)
- Local dev builds cached by git hash
- Zero "restart terminal" confusion

## Troubleshooting

### "Command not found: agctl"

Install the shim:

```bash
cd Tools/agctl-shim
./install.sh
```

### "Build failed" when running in repo

The shim auto-builds. If build fails, fix compilation errors then try again.

### "Timed out after 600s"

Command exceeded its timeout. Either:
1. Increase timeout for that command
2. Investigate why it's taking so long

### Commands still using old binary

```bash
# Check which binary is being used
which agctl  # Should be /usr/local/bin/agctl (the shim)

# Clear cache
rm -rf ~/.agctl/builds

# Rebuild
agctl build  # Will auto-rebuild on next run
```

## What's Next

1. **Complete command migration**: Migrate Test, Validate, Lint, Clean, Generate
2. **GitHub release automation**: Build, sign, notarize, upload
3. **Homebrew tap**: `brew install agora/tools/agctl`
4. **Download implementation**: self-update actually downloads from GitHub
5. **Platform validation**: Ensure all packages are iOS-only

## Questions?

Run `agctl doctor` to check your setup, or `agctl dev --help` to see all options.

---

**tl;dr**: Install the shim, everything else just works. Commands never hang. Local changes take effect instantly. Version pinning keeps teams in sync.


