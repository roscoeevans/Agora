# agctl Quick Start

## Installation

```bash
cd Tools/agctl
./install.sh
agctl install-hooks
```

## Essential Commands

### OpenAPI Generation
```bash
agctl generate openapi              # Regenerate API client
agctl generate openapi -v           # Verbose output
```

### Building
```bash
agctl build                         # Build all packages
agctl build AuthFeature             # Build specific package
agctl build --release               # Release build
agctl build -v                      # Verbose output
```

### Testing
```bash
agctl test                          # Test all packages
agctl test AuthFeature              # Test specific package
agctl test --parallel               # Parallel testing
```

### Validation
```bash
agctl validate modules              # Check module structure
agctl validate dependencies         # Check dependency graph
```

### Cleaning
```bash
agctl clean                        # Clean build artifacts
agctl clean --all                  # Deep clean (includes DerivedData)
agctl clean -v                     # Verbose output
```

### Git Hooks
```bash
agctl install-hooks                 # Install git hooks
agctl install-hooks --force         # Force reinstall
```

## Common Workflows

### Daily Development
```bash
agctl build AuthFeature
agctl test AuthFeature
git commit -m "feat: add login"     # pre-commit hook runs automatically
```

### After OpenAPI Changes
```bash
vim OpenAPI/agora.yaml
agctl generate openapi
agctl build Networking
```

### Before Pushing
```bash
agctl validate modules
agctl build
agctl test
```

## Getting Help

```bash
agctl --help                        # All commands
agctl generate --help               # Generate subcommands
agctl build --help                  # Build options
```

## Troubleshooting

**Command not found**: Run `cd Tools/agctl && ./install.sh`

**OpenAPI fails**: Install generator with `brew install mint && mint install apple/swift-openapi-generator`

**Package not found**: Use `agctl build` to list available packages

**Build issues**: Try `agctl clean` or `agctl clean --all` to remove stale artifacts

**Skip git hook**: Use `git commit --no-verify`

## Documentation

- Tool README: `Tools/agctl/README.md`
- Full Guide: `docs/AGCTL_GUIDE.md`
- Git Hooks: `.githooks/README.md`

