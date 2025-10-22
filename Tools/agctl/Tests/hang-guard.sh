#!/usr/bin/env bash
# CI hang-guard test: ensures commands exit within reasonable time
set -euo pipefail

TIMEOUT=60  # seconds
AGCTL="${1:-agctl}"

echo "🔒 Running hang-guard tests..."
echo "Testing: $AGCTL"
echo ""

commands=(
    "--version"
    "--help"
    "build --help"
    "test --help"
    "validate --help"
    "lint --help"
    "clean --help"
    "generate --help"
    "config show"
    "doctor"
)

failed=0

for cmd in "${commands[@]}"; do
    echo -n "Testing 'agctl $cmd'... "
    
    if timeout $TIMEOUT $AGCTL $cmd > /dev/null 2>&1; then
        echo "✅"
    else
        exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo "❌ TIMEOUT (hung for ${TIMEOUT}s)"
            failed=$((failed + 1))
        else
            echo "✅ (exit $exit_code)"
        fi
    fi
done

echo ""

if [ $failed -eq 0 ]; then
    echo "✅ All commands completed within ${TIMEOUT}s"
    exit 0
else
    echo "❌ $failed command(s) timed out"
    exit 1
fi


