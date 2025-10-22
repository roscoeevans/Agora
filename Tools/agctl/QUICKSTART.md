# agctl 1.1.0 Quick Start Guide

## 🚀 Install in 3 Steps

### 1. Install agctl

```bash
cd /Users/roscoeevans/Developer/Agora/Tools/agctl
./install.sh
```

### 2. Install Shell Completions (Optional but Recommended)

**For Zsh** (macOS default):
```bash
agctl completions zsh > ~/.zsh/completions/_agctl
# Add to ~/.zshrc if not already there:
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
# Then restart shell or:
source ~/.zshrc
```

**For Bash**:
```bash
agctl completions bash > /usr/local/etc/bash_completion.d/agctl
source /usr/local/etc/bash_completion.d/agctl
```

**For Fish**:
```bash
agctl completions fish > ~/.config/fish/completions/agctl.fish
```

### 3. Verify Installation

```bash
agctl --version
# Should show: agctl 1.1.0

agctl config show
# Should display current configuration
```

---

## ✨ Try New Features

### Shell Completions
```bash
agctl <TAB><TAB>
# Shows: build, clean, completions, config, generate, install-hooks, lint, test, validate

agctl build --<TAB><TAB>
# Shows: --verbose, --release, --help
```

### Configuration Management
```bash
# Config already created at project root: .agctl.yml
agctl config show

# To customize:
vim .agctl.yml
```

### Progress Indicators
```bash
# Single package build with spinner
agctl build AuthFeature
# ⠋ Building AuthFeature (2.3s)
# ✅ Build succeeded (2.4s)

# All packages with progress bar
agctl build
# Building: [████████████████████░░░░] 85% (12/14) - PostDetailFeature
```

### Code Linting
```bash
# Check if SwiftLint is installed
which swiftlint
# If not: brew install swiftlint

# Lint a package
agctl lint AuthFeature

# Lint all packages
agctl lint

# Auto-fix issues
agctl lint --fix

# Strict mode (CI)
agctl lint --strict
```

---

## 📝 Common Workflows

### Daily Development
```bash
# Build what you're working on (with nice spinner!)
agctl build AuthFeature

# Lint and fix your code
agctl lint AuthFeature --fix

# Test your changes
agctl test AuthFeature

# Before commit: validate everything
agctl validate modules
agctl build
```

### Code Review Preparation
```bash
# Make sure everything is clean
agctl clean
agctl build --release
agctl lint --fix
agctl test
agctl validate modules
```

### CI/CD
```bash
agctl validate modules
agctl validate dependencies
agctl lint --strict
agctl build --release
agctl test
```

---

## 🎯 What's New in 1.1.0

1. **Shell Completions** - Tab completion for all commands
2. **Config File** - Team-wide settings in `.agctl.yml`
3. **Progress Bars** - Beautiful progress indicators
4. **Lint Command** - `agctl lint` with auto-fix
5. **Test Suite** - Unit tests for core functionality

---

## 💡 Pro Tips

### Use Config for Team Settings
Edit `.agctl.yml` to set team defaults:
```yaml
lint:
  autoFix: true    # Always auto-fix
  strict: true     # CI mode

validation:
  strictNaming: true
  enforceTests: true
```

### Combine Commands
```bash
# Clean, build, lint, test - all in one go
agctl clean && agctl build && agctl lint --fix && agctl test
```

### Create Aliases
Add to your `.zshrc`:
```bash
alias agb='agctl build'
alias agl='agctl lint --fix'
alias agt='agctl test'
alias agv='agctl validate modules'
```

### Use in Git Hooks
The tool is already set up for git hooks:
```bash
agctl install-hooks
```

---

## 🆘 Troubleshooting

### Command Not Found
```bash
# Make sure it's in PATH
which agctl

# If not, reinstall:
cd Tools/agctl && ./install.sh
```

### Tab Completion Not Working
```bash
# For Zsh, make sure fpath includes completions dir
echo $fpath | grep zsh/completions

# Add to ~/.zshrc if missing:
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
```

### SwiftLint Not Found
```bash
brew install swiftlint
# Verify:
which swiftlint
```

### Progress Bar Looks Weird
Progress bars work best in modern terminals. If you see issues in CI, use:
```bash
agctl build --verbose  # Disables progress bar
```

---

## 📚 More Info

- Full docs: `Tools/agctl/README.md`
- Implementation details: `AGCTL_TIER1_IMPROVEMENTS.md`
- Help: `agctl --help` or `agctl <command> --help`

---

## 🎉 Enjoy!

You now have a world-class CLI tool for Agora development. Happy coding!
