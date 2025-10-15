# agctl Developer Guide

`agctl` is Agora's command-line tool that simplifies common development tasks. It replaces various shell scripts with a unified, type-safe Swift implementation.

## Quick Start

### Installation

```bash
# From project root
cd Tools/agctl
./install.sh

# Verify installation
agctl --version

# Install git hooks
agctl install-hooks
```

### Common Commands

```bash
# Generate OpenAPI client
agctl generate openapi

# Build a specific module
agctl build AuthFeature

# Test a module
agctl test DesignSystem

# Validate project structure
agctl validate modules
```

## Why agctl?

### Before (Shell Scripts)

```bash
# Different scripts for different tasks
./Scripts/generate-openapi.sh
make api-gen
./Scripts/prebuild.sh

# Hard to discover available commands
# Difficult to maintain and test
# Inconsistent error handling
```

### After (agctl)

```bash
# One unified interface
agctl generate openapi
agctl build AuthFeature
agctl validate modules

# Built-in help system
agctl --help
agctl generate --help

# Type-safe Swift implementation
# Consistent error handling and output
# Easy to extend
```

## Command Reference

### Generate Commands

#### `agctl generate openapi`

Generates the OpenAPI client from `OpenAPI/agora.yaml`.

**Replaces**: `Scripts/generate-openapi.sh`, `make api-gen`

**Options**:
- `-v, --verbose`: Show detailed generation output

**How it works**:
1. Cleans `Packages/Kits/Networking/Sources/Networking/Generated`
2. Tries multiple generation methods (Mint → Homebrew → SPM → Docker)
3. Uses the first available method
4. Updates `OpenAPI/VERSION.lock` on success

**Example**:
```bash
agctl generate openapi
```

#### `agctl generate mocks`

Generates mock data for SwiftUI previews.

**Output**: `Packages/Shared/TestSupport/Sources/TestSupport/Mocks/Generated/`

**Generates**:
- `MockProfiles.swift`: Sample user profiles
- `MockPosts.swift`: Sample posts with various content types

**Example**:
```bash
agctl generate mocks
```

### Build Commands

#### `agctl build [package-name]`

Builds Swift packages individually or all at once.

**Examples**:
```bash
# Build specific package
agctl build AuthFeature
agctl build DesignSystem

# Build all packages (in dependency order)
agctl build

# Release build
agctl build --release
```

**Options**:
- `-v, --verbose`: Show full build output
- `-r, --release`: Build in release configuration

**Build Order**:
When building all packages, they're built in dependency order:
1. Shared packages (AppFoundation, TestSupport)
2. Kits (DesignSystem, Networking, etc.)
3. Features (Auth, Home, Profile, etc.)

### Test Commands

#### `agctl test [package-name]`

Runs tests for packages.

**Examples**:
```bash
# Test specific package
agctl test AuthFeature
agctl test DesignSystem

# Test all packages
agctl test

# Parallel testing
agctl test --parallel
```

**Options**:
- `-v, --verbose`: Show detailed test output
- `--parallel`: Run tests in parallel (faster, but harder to debug failures)

**Output**:
- Test counts (passed, failed, skipped)
- Summary across all packages
- Exit code 0 if all tests pass, 1 if any fail

### Validate Commands

#### `agctl validate modules`

Validates module structure and architecture rules.

**Checks**:
- **Naming**: Features should end with "Feature" suffix
- **Structure**: Required directories exist (Sources, Tests)
- **Dependencies**: 
  - Features don't depend on other Features
  - Kits only depend on Shared or other Kits
  - Shared packages don't depend on local packages

**Example**:
```bash
agctl validate modules
```

**Use Cases**:
- Pre-commit validation
- CI/CD pipeline checks
- Catching accidental circular dependencies
- Ensuring architecture guidelines are followed

#### `agctl validate dependencies`

Validates the dependency graph.

**Checks**:
- No circular dependencies
- All local dependencies exist
- Valid relative paths in Package.swift files

**Example**:
```bash
agctl validate dependencies
```

**Common Issues Caught**:
- Package A depends on B, B depends on C, C depends on A
- Feature depends on another Feature (violates architecture)
- Typo in package name
- Wrong relative path in `.package(path:)`

### Git Hooks

#### `agctl install-hooks`

Installs git hooks for automatic validation and code generation.

**Options**:
- `-f, --force`: Overwrite existing hooks

**Installed Hooks**:

**pre-commit**:
- Validates module structure
- Runs SwiftLint (warnings only)
- Prevents commits if validation fails

**post-merge**:
- Regenerates OpenAPI client if spec changed
- Notifies if Package.swift changed

**Examples**:
```bash
# Install hooks
agctl install-hooks

# Force reinstall
agctl install-hooks --force

# Skip pre-commit validation once
git commit --no-verify
```

## Workflows

### Daily Development

```bash
# 1. Start working on a feature
cd ~/Developer/Agora

# 2. Build the module you're working on
agctl build AuthFeature

# 3. Run tests
agctl test AuthFeature

# 4. Before committing
agctl validate modules
git add .
git commit -m "feat: add login flow"
# (pre-commit hook runs automatically)
```

### OpenAPI Changes

```bash
# 1. Edit the spec
vim OpenAPI/agora.yaml

# 2. Regenerate client
agctl generate openapi

# 3. Rebuild Networking module
agctl build Networking

# 4. Update code using new API
# ...

# 5. Commit (hook will catch if spec needs regeneration)
git commit -am "feat: add new API endpoint"
```

### Adding a New Module

```bash
# 1. Create package structure
mkdir -p Packages/Features/NewFeature/Sources/NewFeature
mkdir -p Packages/Features/NewFeature/Tests/NewFeatureTests

# 2. Create Package.swift
# ... (see ios-module-standards rule)

# 3. Validate structure
agctl validate modules
agctl validate dependencies

# 4. Build and test
agctl build NewFeature
agctl test NewFeature
```

### CI/CD Pipeline

```bash
#!/bin/bash
# .github/workflows/ci.yml equivalent

# Install agctl
cd Tools/agctl
./install.sh

# Validate everything
agctl validate modules
agctl validate dependencies

# Build all packages
agctl build --release

# Run all tests
agctl test --parallel

# Generate fresh OpenAPI client
agctl generate openapi

# Check if any generated files changed
if git diff --exit-code Packages/Kits/Networking/Sources/Networking/Generated; then
    echo "✅ Generated code is up to date"
else
    echo "❌ Generated code is out of sync"
    exit 1
fi
```

## Troubleshooting

### Command Not Found

**Problem**: `agctl: command not found`

**Solution**:
```bash
cd Tools/agctl
./install.sh
# Or manually:
swift build -c release
sudo cp .build/release/agctl /usr/local/bin/
```

### OpenAPI Generation Fails

**Problem**: `No OpenAPI generator found!`

**Solution**: Install swift-openapi-generator:
```bash
# Via Mint (recommended)
brew install mint
mint install apple/swift-openapi-generator

# Via Homebrew
brew install swift-openapi-generator
```

### Package Not Found

**Problem**: `Package 'Auth' not found`

**Solution**: Use the correct package name:
```bash
# List all packages
agctl build  # Will list available packages

# Features end with "Feature" or use directory name
agctl build AuthFeature  # ✅
agctl build Auth         # ❌
```

### Module Validation Fails

**Problem**: Too many validation errors for intentional architecture

**Solution**: Validation rules are intentionally strict. Options:
1. Fix the architecture (recommended)
2. Use `--no-verify` to skip pre-commit hook
3. Adjust validation rules in `ValidateCommand.swift`

### Git Hook Not Running

**Problem**: Hooks aren't executing automatically

**Solution**:
```bash
# Reinstall hooks
agctl install-hooks --force

# Check they exist
ls -la .git/hooks/

# Make sure they're executable
chmod +x .git/hooks/*

# Test manually
.git/hooks/pre-commit
```

## Architecture

### Design Principles

1. **Unified Interface**: One command for all dev tasks
2. **Type Safety**: Swift implementation over shell scripts
3. **Discoverability**: Built-in help for all commands
4. **Progressive Enhancement**: Graceful fallbacks (e.g., OpenAPI generation)
5. **CI-Friendly**: Non-interactive, clear exit codes

### Code Organization

```
Tools/agctl/
├── Package.swift                    # SPM manifest
├── Sources/agctl/
│   ├── AGCTLCommand.swift          # Root command (@main)
│   ├── Commands/                    # Subcommands
│   │   ├── GenerateCommand.swift   
│   │   ├── BuildCommand.swift      
│   │   ├── TestCommand.swift       
│   │   ├── ValidateCommand.swift   
│   │   └── InstallHooksCommand.swift
│   └── Core/                        # Utilities
│       ├── Shell.swift             # Process execution
│       ├── FileSystem.swift        # File operations
│       ├── Logger.swift            # Pretty printing
│       └── PackageResolver.swift   # Package discovery
├── README.md                        # Tool-specific docs
└── install.sh                       # Installation script
```

### Adding New Commands

1. Create command file in `Commands/`:

```swift
// Commands/NewCommand.swift
import ArgumentParser

struct NewCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Does something new"
    )
    
    @Flag(name: .shortAndLong)
    var verbose = false
    
    func run() throws {
        Logger.section("🎯 Doing Something New")
        // Implementation
        Logger.success("Done!")
    }
}
```

2. Register in `AGCTLCommand.swift`:

```swift
@main
struct AGCTLCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        // ...
        subcommands: [
            // ... existing commands
            NewCommand.self  // Add here
        ]
    )
}
```

3. Rebuild and test:

```bash
cd Tools/agctl
swift build
.build/debug/agctl new --help
```

## Migration Guide

### From Shell Scripts

| Old Command | New Command |
|-------------|-------------|
| `./Scripts/generate-openapi.sh` | `agctl generate openapi` |
| `make api-gen` | `agctl generate openapi` |
| `make api-clean` | `agctl generate openapi` (auto-cleans) |
| `./Scripts/prebuild.sh` | Automatic via git hooks |
| Manual module builds | `agctl build [module]` |
| Manual testing | `agctl test [module]` |

### Updating CI/CD

Replace script calls with `agctl` commands:

```yaml
# Before
- run: ./Scripts/generate-openapi.sh
- run: make api-gen

# After
- run: agctl generate openapi
```

### Xcode Build Phases

If you had run script phases calling `Scripts/*.sh`, replace with:

```bash
# Old
"${PROJECT_DIR}/Scripts/generate-openapi.sh"

# New
agctl generate openapi
```

## Best Practices

### Use Verbose Mode for Debugging

```bash
agctl generate openapi -v
agctl build AuthFeature -v
```

### Validate Before Committing

```bash
# Git hooks do this automatically, but you can run manually:
agctl validate modules
agctl validate dependencies
```

### Build in Dependency Order

```bash
# Build everything to catch dependency issues
agctl build
```

### Parallel Testing for Speed

```bash
# Faster feedback
agctl test --parallel
```

### Keep Generated Code Fresh

```bash
# After pulling changes
agctl generate openapi
```

## FAQ

**Q: Why Swift instead of shell scripts?**
A: Type safety, better error handling, easier testing, unified tooling, and familiarity for iOS developers.

**Q: Can I still use the old scripts?**
A: They've been removed. Use `agctl` commands instead.

**Q: How do I skip git hooks?**
A: Use `git commit --no-verify` or `git commit -n`.

**Q: Can I customize validation rules?**
A: Yes, edit `Tools/agctl/Sources/agctl/Commands/ValidateCommand.swift` and rebuild.

**Q: Does this work with Mint?**
A: Yes! You can install agctl via Mint: `mint install . --executable agctl` (from Tools/agctl directory)

**Q: What if I don't have agctl installed?**
A: Git hooks gracefully warn and skip validation if agctl isn't found.

## Related Documentation

- [Tool README](../../Tools/agctl/README.md) - Detailed command reference
- [Module Standards](../../.cursor/rules/ios-module-standards.mdc) - Package structure guidelines
- [Project Structure](../../.cursor/rules/project-structure.mdc) - Where files belong
- [OpenAPI Integration](../../OPENAPI_INTEGRATION.md) - API client setup

## Support

For issues or questions:
1. Check this guide and the tool README
2. Run with `--verbose` flag for more details
3. Check git hook logs
4. Review validation errors carefully
5. Ask the team

