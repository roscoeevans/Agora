# agctl Auto-Rebuild System

## Problem
When developing agctl, you need to manually rebuild and reinstall after every change. This is tedious and easy to forget.

## Solutions

We provide **3 ways** to auto-rebuild agctl:

### 1. Git Post-Commit Hook (Automatic) ⭐ RECOMMENDED

**How it works:** Automatically rebuilds and reinstalls agctl whenever you commit changes to `Tools/agctl/`

**Setup:** Already installed at `.git/hooks/post-commit`

**Usage:** Just commit your changes:
```bash
git add Tools/agctl/Sources/agctl/Core/Shell.swift
git commit -m "Fix hanging issue"
# 🔧 agctl source files changed, rebuilding...
# ✅ agctl rebuilt successfully
# ✅ agctl installed to /usr/local/bin
```

**Pros:**
- Fully automatic
- Only runs when needed
- Integrated with your workflow

**Cons:**
- Requires sudo password on first run after reboot
- Only runs on commit (not during active development)

---

### 2. File Watcher (Active Development)

**How it works:** Watches for file changes and rebuilds immediately

**Setup:** Run in a separate terminal:
```bash
cd Tools/agctl
./.watchman
```

**Usage:** Edit files and save - auto-rebuilds in 2 seconds

**Pros:**
- Instant feedback during development
- No need to commit to test

**Cons:**
- Requires separate terminal
- Runs continuously
- Needs sudo password occasionally

---

### 3. Quick Rebuild Script (Manual)

**How it works:** Fast manual rebuild and install

**Setup:** Already created at `Tools/agctl/dev-rebuild.sh`

**Usage:**
```bash
# From anywhere in the project:
./Tools/agctl/dev-rebuild.sh

# Or from agctl directory:
cd Tools/agctl
./dev-rebuild.sh
```

**Pros:**
- Simple and reliable
- You control when it runs
- Fastest option

**Cons:**
- Manual (need to remember to run it)

---

## Workflow Recommendation

### During Active Development
```bash
# Terminal 1: Edit code
vim Tools/agctl/Sources/agctl/Core/Shell.swift

# Terminal 2: Watch for changes
cd Tools/agctl && ./.watchman
```

### After Finishing a Feature
```bash
# Commit (triggers auto-rebuild)
git add Tools/agctl/
git commit -m "Fix pipe handling"
# ✅ Automatically rebuilds and installs!
```

### Quick Test After Small Change
```bash
# Make change, then:
./Tools/agctl/dev-rebuild.sh
agctl build AuthFeature  # Test immediately
```

---

## Troubleshooting

### "sudo: a password is required"
Normal! Enter your password. It's cached for ~5 minutes, so you won't be prompted repeatedly.

### Post-commit hook not running
Check if it's executable:
```bash
ls -la .git/hooks/post-commit
chmod +x .git/hooks/post-commit
```

### Watcher not detecting changes
Make sure you're editing files in `Tools/agctl/Sources/`:
```bash
# Check what it's watching:
find Tools/agctl/Sources -name "*.swift"
```

### Build fails
Run verbose build to see errors:
```bash
cd Tools/agctl
swift build --configuration release -v
```

---

## Version Checking

Always verify the installed version after rebuild:

```bash
# Check which agctl is running
which agctl
# Should show: /usr/local/bin/agctl

# Check version
agctl --version
# Should show: 1.1.0 (or higher after fixes)

# Full diagnostic
echo "Path: $(which agctl)"
echo "Version: $(agctl --version)"
echo "Last modified: $(stat -f "%Sm" /usr/local/bin/agctl)"
```

---

## Disabling Auto-Rebuild

### Disable post-commit hook:
```bash
chmod -x .git/hooks/post-commit
```

### Re-enable:
```bash
chmod +x .git/hooks/post-commit
```

### Stop file watcher:
Press `Ctrl+C` in the terminal running `.watchman`









