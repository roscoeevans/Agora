# agctl - Agora Command Line Tool

A Swift-based CLI tool for automating common development tasks in the Agora iOS project.

## Features

- **Generate**: OpenAPI client code generation and mock data creation
- **Build**: Build individual packages or all packages in dependency order with progress indicators
- **Test**: Run tests for individual packages or the entire project
- **Validate**: Check module structure and dependency graph integrity
- **Lint**: Run SwiftLint on packages with auto-fix support
- **Clean**: Remove Xcode build artifacts, derived data, and caches
- **Config**: Manage project-wide configuration via .agctl.yml
- **Completions**: Generate shell completion scripts for bash, zsh, and fish
- **Git Hooks**: Automatic validation and code generation via git hooks

## Installation

### Quick Install

```bash
cd Tools/agctl
swift build -c release
sudo cp .build/release/agctl /usr/local/bin/
```

### Install Git Hooks

```bash
agctl install-hooks
```

This will install pre-commit and post-merge hooks that automatically:
- Validate module structure before commits
- Regenerate OpenAPI client when the spec changes after merges

### Install Shell Completions

```bash
# Bash
agctl completions bash > /etc/bash_completion.d/agctl

# Zsh
agctl completions zsh > ~/.zsh/completions/_agctl

# Fish
agctl completions fish > ~/.config/fish/completions/agctl.fish
```

## Configuration

### Create Configuration File

```bash
agctl config init
```

This creates a `.agctl.yml` file at the project root with default settings.

### View Current Configuration

```bash
agctl config show
```

### Configuration Options

Edit `.agctl.yml` to customize behavior:

```yaml
build:
  defaultConfiguration: debug  # or release
  parallelJobs: 4
  verbose: false

validation:
  strictNaming: true
  allowFeatureDeps: false
  enforceTests: false

generate:
  openapi:
    specPath: OpenAPI/agora.yaml
    outputPath: Packages/Kits/Networking/Sources/Networking/Generated

lint:
  autoFix: false
  strict: false
  # configPath: .swiftlint.yml  # optional
```

## Usage

### Generate Commands

#### Generate OpenAPI Client

```bash
agctl generate openapi
```

Replaces the old `Scripts/generate-openapi.sh`. Tries multiple generation methods (Mint, Homebrew, SPM plugin, Docker) and uses the first available.

Options:
- `-v, --verbose`: Show detailed output

#### Generate Mock Data

```bash
agctl generate mocks
```

Generates mock profiles and posts for SwiftUI previews in `Packages/Shared/TestSupport`.

### Build Commands

#### Build a Specific Package

```bash
agctl build AuthFeature
agctl build DesignSystem
```

Shows a spinner with elapsed time for better feedback!

#### Build All Packages

```bash
agctl build
```

Builds all packages in dependency order (Shared → Kits → Features) with a progress bar.

Options:
- `-v, --verbose`: Show verbose build output
- `-r, --release`: Build in release configuration

### Test Commands

#### Test a Specific Package

```bash
agctl test AuthFeature
agctl test DesignSystem
```

#### Test All Packages

```bash
agctl test
```

Runs tests for all packages and provides a summary.

Options:
- `-v, --verbose`: Show verbose test output
- `--parallel`: Run tests in parallel

### Lint Commands

#### Lint a Specific Package

```bash
agctl lint AuthFeature
```

#### Lint All Packages

```bash
agctl lint
```

Runs SwiftLint on all packages with a progress bar.

Options:
- `-v, --verbose`: Show verbose lint output
- `--fix`: Automatically fix issues when possible
- `--strict`: Treat warnings as errors
- `--config <path>`: Use custom SwiftLint configuration

**Requirements**: SwiftLint must be installed:
```bash
# Via Homebrew
brew install swiftlint

# Via Mint
mint install realm/SwiftLint
```

### Validate Commands

#### Validate Module Structure

```bash
agctl validate modules
```

Checks:
- Naming conventions (Features should end with "Feature")
- Features don't depend on other Features
- Kits only depend on Shared or other Kits
- Shared packages don't depend on Kits or Features
- Test directories exist

#### Validate Dependencies

```bash
agctl validate dependencies
```

Checks:
- No circular dependencies
- All local package dependencies exist
- Relative paths are valid

#### Validate Platforms

```bash
agctl validate platforms
```

Checks:
- All packages declare iOS-only platforms (no macOS, watchOS, tvOS, visionOS)
- Platform declarations use consistent iOS version (.iOS(.v26))
- No @available annotations for non-iOS platforms
- No platform-specific conditionals (#if os(macOS), etc.)
- No macOS-specific code or comments

### Clean Commands

#### Clean Build Artifacts

```bash
agctl clean
```

Cleans:
- Project build folder
- Swift Package Manager `.build` directories (for all packages and agctl itself)

#### Clean Everything

```bash
agctl clean --all
```

Additionally cleans:
- DerivedData (project-specific folders)
- Module cache (Swift Package Manager and Xcode)

Options:
- `-v, --verbose`: Show detailed output of what's being removed
- `--all`: Clean everything including DerivedData and module cache

**Tip**: Use `agctl clean --all` when experiencing weird build issues, caching problems, or after switching branches with major changes.

### Config Commands

#### Initialize Configuration

```bash
agctl config init
```

Creates a `.agctl.yml` file with default settings.

Options:
- `-f, --force`: Overwrite existing configuration

#### Show Configuration

```bash
agctl config show
```

Displays current configuration and whether it's from `.agctl.yml` or defaults.

### Completions Commands

#### Generate Shell Completions

```bash
# Bash
agctl completions bash > /etc/bash_completion.d/agctl

# Zsh
agctl completions zsh > ~/.zsh/completions/_agctl

# Fish
agctl completions fish > ~/.config/fish/completions/agctl.fish
```

After installing completions, restart your shell or source the completion file:

```bash
# Bash
source /etc/bash_completion.d/agctl

# Zsh
source ~/.zsh/completions/_agctl
```

### AI-Powered Commands

#### Auto-Fix Common Issues

```bash
agctl auto-fix
agctl auto-fix AuthFeature
```

Automatically detects and fixes common build issues:
- Import problems
- Concurrency issues
- Sendable requirements
- Type compatibility problems

#### Performance Profiling

```bash
agctl profile show
agctl profile analyze
agctl profile clear
```

Analyze build performance and get optimization suggestions.

#### Telemetry & Analytics

```bash
agctl telemetry show
agctl telemetry enable
agctl telemetry disable
agctl telemetry clear
```

View usage analytics and manage telemetry collection.

### Plugin System

#### Manage Plugins

```bash
# List installed plugins
agctl plugin list

# Install a plugin
agctl plugin install https://github.com/team/agctl-plugin

# Uninstall a plugin
agctl plugin uninstall plugin-name
```

### Git Hooks

#### Install Hooks

```bash
agctl install-hooks
```

Options:
- `-f, --force`: Overwrite existing hooks

Installed hooks:
- **pre-commit**: Validates module structure before allowing commits
- **post-merge**: Regenerates OpenAPI client if spec changed

## Architecture

```
Tools/agctl/
├── Package.swift                  # Swift Package Manager manifest
├── Sources/agctl/
│   ├── AGCTLCommand.swift        # Root command
│   ├── Commands/
│   │   ├── GenerateCommand.swift # OpenAPI and mock generation
│   │   ├── BuildCommand.swift    # Package building
│   │   ├── TestCommand.swift     # Package testing
│   │   ├── ValidateCommand.swift # Validation rules
│   │   ├── LintCommand.swift     # SwiftLint integration
│   │   ├── CleanCommand.swift    # Clean build artifacts
│   │   ├── ConfigCommand.swift   # Configuration management
│   │   ├── CompletionsCommand.swift # Shell completions
│   │   └── InstallHooksCommand.swift
│   └── Core/
│       ├── Shell.swift           # Shell command execution
│       ├── FileSystem.swift      # File operations
│       ├── Logger.swift          # Pretty output
│       ├── Progress.swift        # Progress indicators & spinners
│       ├── Config.swift          # Configuration management
│       └── PackageResolver.swift # Package discovery and parsing
└── Tests/agctlTests/
    ├── ConfigTests.swift
    ├── LoggerTests.swift
    ├── ShellTests.swift
    └── ProgressTests.swift
```

## Examples

### Daily Development Workflow

```bash
# Build a specific module you're working on
agctl build AuthFeature
# ⠋ Building AuthFeature (2.3s)
# ✅ Build succeeded (2.4s)

# If build fails, get AI-powered suggestions
agctl build AuthFeature
# 🤖 AI Error Analysis
# I found some issues and have suggestions:
# • Check if the module is properly declared in Package.swift
# • Ensure the module is built before this one
# • Run 'agctl build' to build all dependencies first
# 
# I can try to fix these automatically:
# • Build all dependencies
# • Check import statements
# 
# Run 'agctl auto-fix AuthFeature' to attempt automatic fixes

# Auto-fix common issues
agctl auto-fix AuthFeature
# 🔧 Auto-Fix
# Applied fixes:
# • Fixed imports in AuthService.swift
# • Fixed concurrency issues in AuthViewModel.swift
# ✅ Build successful after auto-fix!

# Test your changes
agctl test AuthFeature

# Lint your code
agctl lint AuthFeature --fix

# Build everything before committing
agctl build
# Building: [████████████████████░░░░] 85% (12/14) - PostDetailFeature

# Validate structure
agctl validate modules

# Regenerate OpenAPI if spec changed
agctl generate openapi

# Clean build artifacts when needed
agctl clean

# Deep clean when experiencing build issues
agctl clean --all

# Check performance and get optimization suggestions
agctl build --profile
# 📊 Build Performance Analysis
# Build duration: 2m 15s
# Build is 15.2% faster than average! 🚀
# Optimization suggestions:
# • Try building with more parallel jobs: agctl build --parallel=8
# • Consider using 'agctl build --incremental' for faster rebuilds

# View usage analytics
agctl telemetry show
# 📊 Usage Analytics
# Total sessions: 42
# Total commands: 156
# Average build time: 1m 45s
# Error rate: 12.5%
# Most used commands:
# • build: 45 times
# • test: 32 times
# • lint: 28 times
```

### CI/CD Integration

```bash
# Full validation and build
agctl validate modules
agctl validate dependencies
agctl lint --strict
agctl build --release
agctl test
```

### Configuration Management

```bash
# Create config file
agctl config init

# Edit .agctl.yml to your needs
vim .agctl.yml

# View active configuration
agctl config show
```

## What's New in v1.4.0 - 2025 Edition

### 🤖 AI-Powered Error Analysis
- Intelligent error pattern recognition and suggestions
- Automatic detection of common build issues
- Smart recommendations for fixing circular dependencies, import errors, and concurrency issues
- Context-aware error analysis based on package type and recent changes

### 🔧 Auto-Fix System
- `agctl auto-fix` command to automatically resolve common issues
- Fixes import problems, concurrency issues, and Sendable requirements
- Smart code transformation for Swift 6.2 concurrency
- Safe, reversible changes with detailed reporting

### 🔌 Plugin System
- `agctl plugin` commands for extending functionality
- Team-specific custom commands and workflows
- Easy plugin installation from Git repositories
- Protocol-based architecture for clean extensions

### 📊 Performance Profiling
- `agctl profile` command for build performance analysis
- Historical performance tracking and trends
- Optimization suggestions based on build patterns
- Identify slow packages and bottlenecks

### 📈 Telemetry & Analytics
- `agctl telemetry` command for usage insights
- Anonymous usage data collection (opt-in)
- Performance metrics and error rate tracking
- Feature usage analytics for continuous improvement

### 🎉 Shell Completions
- Full tab completion support for bash, zsh, and fish
- Auto-complete commands, subcommands, and options
- Massive productivity boost

### ⚙️ Configuration File Support
- Create `.agctl.yml` for team-wide settings
- Override defaults for build, validation, lint, and generate commands
- `agctl config init` to get started

### 🧪 Test Suite
- Comprehensive tests for core functionality
- Unit tests for Config, Shell, Logger, and Progress
- Run with `swift test`

### ⏱️ Progress Indicators
- Beautiful spinners for long-running commands
- Progress bars for batch operations (build all, lint all)
- Elapsed time tracking
- Better user feedback

### 🧹 Lint Command
- `agctl lint` to run SwiftLint on packages
- Auto-fix support with `--fix` flag
- Strict mode to treat warnings as errors
- Progress bar for linting multiple packages
- JSON output parsing for accurate statistics

## Replacing Old Scripts

`agctl` replaces the following:

- `Scripts/generate-openapi.sh` → `agctl generate openapi`
- `Scripts/prebuild.sh` → Handled by git hooks
- `Makefile` → Use `agctl` commands directly

## Troubleshooting

### "agctl: command not found"

Make sure you've installed the binary to your PATH:

```bash
cd Tools/agctl
swift build -c release
sudo cp .build/release/agctl /usr/local/bin/
```

### OpenAPI Generation Fails

Install `swift-openapi-generator`:

```bash
# Via Mint (recommended)
brew install mint
mint install apple/swift-openapi-generator

# Via Homebrew
brew install swift-openapi-generator
```

### SwiftLint Not Found

Install SwiftLint:

```bash
# Via Homebrew
brew install swiftlint

# Via Mint
mint install realm/SwiftLint
```

### Package Not Found

List all available packages:

```bash
agctl build  # Will show available packages if name is wrong
```

Package names should match either:
- The display name (directory name): `AuthFeature`, `DesignSystem`
- The package name from `Package.swift`: `AuthFeature`, `DesignSystem`

### Shell Completions Not Working

Make sure to:
1. Install completions to the correct location
2. Restart your shell or source the completion file
3. Check that the completion file has correct permissions

```bash
# Check installation
ls -la ~/.zsh/completions/_agctl  # or appropriate path

# Source manually
source ~/.zsh/completions/_agctl
```

## Contributing

When adding new commands:

1. Create a new command file in `Commands/`
2. Implement `ParsableCommand` protocol
3. Add to `AGCTLCommand.subcommands`
4. Add tests in `Tests/agctlTests/`
5. Update this README

## License

Part of the Agora iOS project.
