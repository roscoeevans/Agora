# Git Hooks for Agora

This directory contains git hook templates that automate validation and code generation tasks.

## Installation

```bash
agctl install-hooks
```

This will copy the hooks from `.githooks/` to `.git/hooks/` and make them executable.

## Available Hooks

### pre-commit

Runs before each commit to validate project structure:

- **Module validation**: Ensures packages follow naming conventions and dependency rules
- **SwiftLint**: Runs linting (warnings only, doesn't block commits)

Skip with: `git commit --no-verify`

### post-merge

Runs after `git pull` or `git merge` to keep generated code up to date:

- **OpenAPI regeneration**: If `OpenAPI/agora.yaml` changed, regenerates the client
- **Package notification**: Warns if `Package.swift` files changed

## Customizing Hooks

Edit the files in `.githooks/` and re-run `agctl install-hooks` to update.

## Manual Installation

If you prefer not to use `agctl`:

```bash
cp .githooks/* .git/hooks/
chmod +x .git/hooks/*
```

## Disabling Hooks

To temporarily disable hooks, you can:

1. Use `--no-verify` flag: `git commit --no-verify`
2. Rename the hook in `.git/hooks/`: `mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled`
3. Delete the hook: `rm .git/hooks/pre-commit`

Note: Hooks in `.git/hooks/` are local to your machine and not tracked by git.

