#!/bin/bash
# Installation script for agctl

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/usr/local/bin"

echo "🔨 Building agctl..."
cd "$SCRIPT_DIR"
swift build -c release

echo ""
echo "📦 Installing to $INSTALL_DIR..."
if [ -w "$INSTALL_DIR" ]; then
    cp .build/release/agctl "$INSTALL_DIR/"
else
    echo "Note: Need sudo to write to $INSTALL_DIR"
    sudo cp .build/release/agctl "$INSTALL_DIR/"
fi

echo ""
echo "✅ agctl installed successfully!"
echo ""
echo "Location: $INSTALL_DIR/agctl"
echo ""
echo "Test installation:"
echo "  agctl --version   # Should show: 1.2.0"
echo "  agctl --help      # Should show help and exit cleanly"
echo ""
echo "Next steps:"
echo "  1. Install git hooks: agctl install-hooks"
echo "  2. Test: agctl generate openapi"
echo "  3. Read: Tools/agctl/README.md"
echo ""

