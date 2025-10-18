# agctl Clean Command Implementation

## Summary

Added a new `clean` command to agctl for clearing Xcode build artifacts and cached data.

## Changes Made

### 1. New Command: `agctl clean`

Created `/Users/roscoeevans/Developer/Agora/Tools/agctl/Sources/agctl/Commands/CleanCommand.swift`

**Features:**
- **Default Mode** (`agctl clean`): Cleans basic build artifacts
  - Project build folder
  - Swift Package Manager `.build` directories (all packages + agctl itself)
  
- **Deep Clean Mode** (`agctl clean --all`): Cleans everything
  - All default items above
  - DerivedData (project-specific folders)
  - Module cache (Swift Package Manager and Xcode)

**Options:**
- `-v, --verbose`: Show detailed output of what's being removed
- `--all`: Clean everything including DerivedData and module cache

**Example Output:**
```bash
$ agctl clean --verbose

🧹 Cleaning Build Artifacts
==========================

ℹ️  Cleaning project build folder...
  → Not found: /Users/roscoeevans/Developer/Agora/build
ℹ️  Cleaning Swift Package Manager cache...
  → Removed: /Users/roscoeevans/Developer/Agora/.build
  → Removed: /Users/roscoeevans/Developer/Agora/Packages/Features/Auth/.build
  → Removed: /Users/roscoeevans/Developer/Agora/Packages/Features/HomeForYou/.build
  ...
  → Removed: /Users/roscoeevans/Developer/Agora/Tools/agctl/.build

✅ Cleaned 2 item(s):
  • Project build folder
  • Swift Package Manager cache

ℹ️  Tip: Use --all to also clean DerivedData and module cache
```

### 2. Updated `AGCTLCommand.swift`

Added `CleanCommand.self` to the subcommands array.

### 3. Updated Documentation

**Tools/agctl/README.md:**
- Added "Clean" to features list
- Added complete "Clean Commands" section with usage examples
- Updated architecture diagram to include CleanCommand.swift
- Added clean examples to daily development workflow

**.cursor/rules/ios-build-testing.mdc:**
- Added clean commands to Quick Reference section
- Updated Dependency Resolution Issues section to recommend `agctl clean --all`
- Added clean commands to "When Issues Arise" checklist

## Usage

### Basic Clean
```bash
agctl clean
```

### Deep Clean (for stubborn build issues)
```bash
agctl clean --all
```

### Verbose Output
```bash
agctl clean --verbose
agctl clean --all --verbose
```

## When to Use

### Use `agctl clean` when:
- Switching between branches
- Build artifacts are stale
- Want to free up disk space
- Before a clean build

### Use `agctl clean --all` when:
- Experiencing weird build issues
- Caching problems persist
- After major changes (Swift version, Xcode update)
- Module cache corruption suspected

## Installation

The command is built but needs to be installed:

```bash
cd /Users/roscoeevans/Developer/Agora/Tools/agctl
./install.sh
```

Or manually:
```bash
cd /Users/roscoeevans/Developer/Agora/Tools/agctl
swift build -c release
sudo cp .build/release/agctl /usr/local/bin/
```

## Files Changed

- ✅ Created: `Tools/agctl/Sources/agctl/Commands/CleanCommand.swift`
- ✅ Modified: `Tools/agctl/Sources/agctl/AGCTLCommand.swift`
- ✅ Modified: `Tools/agctl/README.md`
- ✅ Modified: `.cursor/rules/ios-build-testing.mdc`

## Testing

Tested successfully:
- ✅ `agctl clean --help` - Shows correct help text
- ✅ `agctl clean --verbose` - Removes all `.build` directories
- ✅ Command integrates properly with agctl structure

## Next Steps

1. Install the updated agctl:
   ```bash
   cd /Users/roscoeevans/Developer/Agora/Tools/agctl
   ./install.sh
   ```

2. Try it out:
   ```bash
   agctl clean --verbose
   ```

3. Use `agctl clean --all` when experiencing build issues

## Benefits

- **Faster**: One command instead of multiple manual deletions
- **Complete**: Cleans all relevant locations including hidden `.build` directories
- **Safe**: Only removes build artifacts, not source code
- **Smart**: Targets project-specific DerivedData to avoid affecting other projects
- **Convenient**: Verbose mode shows exactly what's being cleaned
- **Integrated**: Works seamlessly with other agctl commands

## Notes

- The command will remove its own `.build` directory when run, which is intentional
- Use `--all` flag carefully as it removes DerivedData (may slow down next build)
- The clean command is especially useful after git operations like merge, rebase, or branch switch


