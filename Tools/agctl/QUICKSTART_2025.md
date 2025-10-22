# agctl 2025 Edition - Quick Start Guide

Welcome to agctl v1.4.0, the 2025 edition with AI-powered features and modern development tools!

## 🚀 Getting Started

### 1. Install the Latest Version

```bash
# If you have the shim installed (recommended)
agctl self-update

# Or install fresh
cd Tools/agctl-shim
./install.sh
```

### 2. Verify Installation

```bash
agctl --version
# Should show: agctl, version 1.4.0

# Check your installation health
agctl doctor
```

## 🤖 AI-Powered Features

### Smart Error Analysis

When builds fail, agctl now provides intelligent suggestions:

```bash
# Build a package
agctl build AuthFeature

# If it fails, you'll see:
# 🤖 AI Error Analysis
# I found some issues and have suggestions:
# • Check if the module is properly declared in Package.swift
# • Ensure the module is built before this one
# • Run 'agctl build' to build all dependencies first
```

### Auto-Fix Common Issues

Let agctl fix common problems automatically:

```bash
# Auto-fix issues in a specific package
agctl auto-fix AuthFeature

# Auto-fix all packages
agctl auto-fix
```

**What it fixes:**
- Import statement problems
- Swift 6.2 concurrency issues
- Sendable requirement violations
- Type compatibility errors

## 📊 Performance Profiling

### Track Build Performance

```bash
# Build with performance profiling
agctl build --profile

# View performance analytics
agctl profile show

# Get optimization suggestions
agctl profile analyze
```

### Performance Insights

- Historical build time tracking
- Package-specific performance metrics
- Optimization suggestions
- Trend analysis (improving/degrading/stable)

## 📈 Usage Analytics

### View Your Usage Patterns

```bash
# Show usage analytics
agctl telemetry show

# Enable telemetry (opt-in)
agctl telemetry enable

# Disable telemetry
agctl telemetry disable
```

**Analytics include:**
- Most used commands
- Build success rates
- Average build times
- Feature usage patterns

## 🔌 Plugin System

### Install Team Plugins

```bash
# List installed plugins
agctl plugin list

# Install a plugin from GitHub
agctl plugin install https://github.com/your-team/agctl-plugin

# Uninstall a plugin
agctl plugin uninstall plugin-name
```

### Create Your Own Plugin

1. Create a Swift package with `Package.swift`
2. Add `agctl-plugin.json` with metadata
3. Implement the `AGCTLPlugin` protocol
4. Install with `agctl plugin install`

## 🎯 Daily Workflow Examples

### Modern Development Workflow

```bash
# 1. Build with AI assistance
agctl build AuthFeature
# If it fails, get smart suggestions automatically

# 2. Auto-fix common issues
agctl auto-fix AuthFeature

# 3. Test your changes
agctl test AuthFeature

# 4. Check performance
agctl build --profile

# 5. View usage insights
agctl telemetry show
```

### Team Collaboration

```bash
# 1. Install team plugins
agctl plugin install https://github.com/your-team/agctl-standards

# 2. Use team-specific commands
agctl team-lint --standards=company

# 3. Share performance insights
agctl profile show
```

### CI/CD Integration

```bash
# 1. Full validation with AI
agctl validate modules
agctl validate dependencies
agctl lint --strict

# 2. Build with profiling
agctl build --profile --release

# 3. Test with analytics
agctl test --parallel

# 4. Auto-fix any issues
agctl auto-fix
```

## 🔧 Configuration

### Enable All Features

Create `.agctl.yml`:

```yaml
# Enable telemetry
telemetry:
  enabled: true

# Performance profiling
profiling:
  enabled: true
  track_builds: true
  track_tests: true

# AI features
ai:
  error_analysis: true
  auto_fix: true
  suggestions: true

# Plugin settings
plugins:
  auto_load: true
  trusted_sources:
    - "github.com/your-org"
```

### Shell Completions

```bash
# Install completions for your shell
agctl completions zsh > ~/.zsh/completions/_agctl
agctl completions bash > /etc/bash_completion.d/agctl
agctl completions fish > ~/.config/fish/completions/agctl.fish

# Restart your shell
source ~/.zshrc
```

## 🆘 Troubleshooting

### Common Issues

**"AI suggestions not working"**
```bash
# Check if you're in a git repository
git status

# Ensure you have recent changes
git log --oneline -5
```

**"Auto-fix failed"**
```bash
# Check the specific error
agctl auto-fix --verbose

# Try building first to see the error
agctl build --verbose
```

**"Performance data not showing"**
```bash
# Enable profiling
agctl build --profile

# Check if data is being collected
agctl profile show
```

**"Plugins not loading"**
```bash
# Check plugin directory
ls ~/.agctl/plugins/

# Verify plugin structure
agctl plugin list
```

### Get Help

```bash
# Check installation health
agctl doctor

# View all commands
agctl --help

# Get help for specific commands
agctl build --help
agctl auto-fix --help
agctl profile --help
agctl telemetry --help
agctl plugin --help
```

## 🎉 What's New in 2025

### Key Features
- **AI-Powered Error Analysis**: Smart suggestions for build failures
- **Auto-Fix System**: Automatically resolve common issues
- **Performance Profiling**: Track and optimize build performance
- **Usage Analytics**: Understand your development patterns
- **Plugin System**: Extend agctl with team-specific tools

### Benefits
- **Faster Development**: AI suggestions reduce debugging time
- **Better Performance**: Profiling helps optimize build times
- **Team Collaboration**: Plugin system enables shared workflows
- **Data-Driven**: Analytics help improve development practices
- **Modern Tooling**: Built for Swift 6.2 and iOS 26

## 📚 Next Steps

1. **Try the AI features**: Build something and see the smart suggestions
2. **Enable telemetry**: Get insights into your usage patterns
3. **Install plugins**: Extend agctl with team-specific tools
4. **Profile your builds**: Optimize performance with data
5. **Share feedback**: Help improve agctl with your experience

---

**Happy coding with agctl 2025! 🚀**

For more information, see the full [README.md](README.md) and [CHANGELOG.md](CHANGELOG.md).
