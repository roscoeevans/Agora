#!/usr/bin/env bash
set -euo pipefail

echo "🔨 Building agctl shim..."

cd "$(dirname "$0")"

# Build the shim
swift build -c release --product agctl-shim

# Install to /usr/local/bin
INSTALL_PATH="/usr/local/bin/agctl"

if [ -w "/usr/local/bin" ]; then
    cp .build/release/agctl-shim "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
else
    echo "Need sudo to install to /usr/local/bin"
    sudo cp .build/release/agctl-shim "$INSTALL_PATH"
    sudo chmod +x "$INSTALL_PATH"
fi

echo "✅ agctl shim installed to $INSTALL_PATH"
echo ""
echo "The shim will:"
echo "  • Auto-build local changes when in the Agora repo"
echo "  • Use pinned versions from .agctl-version"
echo "  • Download releases from GitHub as needed"
echo ""
echo "Run 'agctl --version' to verify installation."


