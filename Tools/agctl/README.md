# agctl - Agora Command Line Tool

A Swift-based CLI tool for automating common development tasks in the Agora iOS project.

## Features

- **Generate**: OpenAPI client code generation and mock data creation
- **Build**: Build individual packages or all packages in dependency order
- **Test**: Run tests for individual packages or the entire project
- **Validate**: Check module structure and dependency graph integrity
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

#### Build All Packages

```bash
agctl build
```

Builds all packages in dependency order (Shared → Kits → Features).

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
└── Sources/agctl/
    ├── AGCTLCommand.swift        # Root command
    ├── Commands/
    │   ├── GenerateCommand.swift # OpenAPI and mock generation
    │   ├── BuildCommand.swift    # Package building
    │   ├── TestCommand.swift     # Package testing
    │   ├── ValidateCommand.swift # Validation rules
    │   └── InstallHooksCommand.swift
    └── Core/
        ├── Shell.swift           # Shell command execution
        ├── FileSystem.swift      # File operations
        ├── Logger.swift          # Pretty output
        └── PackageResolver.swift # Package discovery and parsing
```

## Examples

### Daily Development Workflow

```bash
# Build a specific module you're working on
agctl build AuthFeature

# Test your changes
agctl test AuthFeature

# Build everything before committing
agctl build
agctl validate modules

# Regenerate OpenAPI if spec changed
agctl generate openapi
```

### CI/CD Integration

```bash
# Full validation and build
agctl validate modules
agctl validate dependencies
agctl build --release
agctl test
```

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

### Package Not Found

List all available packages:

```bash
agctl build  # Will show available packages if name is wrong
```

Package names should match either:
- The display name (directory name): `AuthFeature`, `DesignSystem`
- The package name from `Package.swift`: `AuthFeature`, `DesignSystem`

## Contributing

When adding new commands:

1. Create a new command file in `Commands/`
2. Implement `ParsableCommand` protocol
3. Add to `AGCTLCommand.subcommands`
4. Update this README

## License

Part of the Agora iOS project.

