# agctl Bootstrap Shim

A tiny (~3KB), stable launcher that ensures you always run the right version of agctl.

## What It Does

The shim resolves which agctl binary to execute:

1. **Local dev build** (if in Agora repo with changes)
   - Checks `Tools/agctl/` sources
   - Auto-rebuilds if sources newer than cached build
   - Caches by git hash in `~/.agctl/builds/<hash>/`
   - **Result**: Your edits take effect instantly

2. **Pinned version** (from `.agctl-version`)
   - Walks up from current directory looking for `.agctl-version`
   - Uses `~/.agctl/versions/<version>/agctl`
   - Downloads from GitHub if missing
   - **Result**: Teams and CI stay in sync

3. **Latest installed** (fallback)
   - Uses newest version in `~/.agctl/versions/`
   - **Result**: Always have a working agctl

Then it `exec()`s the resolved binary with your original arguments.

## Installation

```bash
cd Tools/agctl-shim
./install.sh
```

This builds the shim and installs it to `/usr/local/bin/agctl`.

## Verify

```bash
which agctl
# Should show: /usr/local/bin/agctl

agctl --version
# Should show: agctl, version 1.3.0 (or current version)
```

## How It Works

### Example: Local Development

```bash
# You're in the Agora repo
cd ~/Agora

# Edit agctl source code
vim Tools/agctl/Sources/agctl/Core/Logger.swift

# Run agctl
agctl build AuthFeature

# Behind the scenes:
# 1. Shim checks: Am I in Agora repo? YES
# 2. Git hash: abc1234
# 3. Cached build: ~/.agctl/builds/abc1234/agctl
# 4. Cache older than sources? YES
# 5. Rebuild: cd Tools/agctl && swift build -c release
# 6. Cache binary
# 7. Exec cached binary with ["build", "AuthFeature"]
```

**Result**: Your changes are live immediately. No "restart terminal" confusion.

### Example: Version Pinning

```bash
# Your repo has .agctl-version:
cat .agctl-version
# 1.3.0

# Run agctl
agctl validate modules

# Behind the scenes:
# 1. Shim checks: Not in Agora repo
# 2. Found .agctl-version: 1.3.0
# 3. Binary exists? ~/.agctl/versions/1.3.0/agctl
#    YES: exec it
#    NO: Download from GitHub, then exec
```

**Result**: Everyone on the team uses 1.3.0. CI uses 1.3.0. No version drift.

## Cache Directories

The shim uses:

```
~/.agctl/
├── versions/          # Released versions
│   ├── 1.2.0/
│   │   └── agctl
│   ├── 1.3.0/
│   │   └── agctl
│   └── ...
└── builds/            # Dev builds (by git hash)
    ├── abc1234/
    │   └── agctl
    └── ...
```

Clear cache:
```bash
rm -rf ~/.agctl/builds/*
```

## Updating the Shim

The shim itself rarely needs updates (it's just routing logic). But if needed:

```bash
cd Tools/agctl-shim
git pull
./install.sh
```

## Uninstalling

```bash
sudo rm /usr/local/bin/agctl
rm -rf ~/.agctl
```

## Troubleshooting

### "Command not found: agctl"

The shim isn't installed. Run `./install.sh`.

### Commands using wrong version

Check resolution:
```bash
# See which binary would be used
/usr/local/bin/agctl --version

# Check .agctl-version
cat .agctl-version

# Clear build cache
rm -rf ~/.agctl/builds/*
```

### Build failures in dev mode

The shim tries to auto-build. If compilation fails:
1. Fix the errors in `Tools/agctl/`
2. Run `agctl` again (will retry build)

Or build manually:
```bash
cd Tools/agctl
swift build -c release
```

## Design Philosophy

**Tiny and stable**: The shim should rarely change. All the complex logic lives in agctl itself.

**Zero config**: Just install once, everything else is automatic.

**No magic**: Simple priority list (dev → pinned → latest). Easy to debug.

**Fast**: Stat a few files, maybe fork/exec swift build. Sub-second overhead.

## Related

- Main agctl README: `../agctl/README.md`
- Migration guide: `../agctl/MIGRATION_GUIDE.md`
- Implementation notes: `../../AGCTL_1.3_IMPLEMENTATION.md`

---

**tl;dr**: Install once (`./install.sh`), then forget about it. The shim handles everything.


