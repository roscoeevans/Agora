#!/bin/bash
# Quick rebuild and install script for agctl development

set -e

cd "$(dirname "$0")"

echo "🔨 Building agctl..."
swift build --configuration release

echo "📦 Installing to /usr/local/bin..."
sudo cp -f .build/release/agctl /usr/local/bin/agctl
sudo chmod +x /usr/local/bin/agctl

echo "✅ Done!"
echo ""
echo "Installation complete. Test with:"
echo "  agctl --version   # Should show: 1.2.0 and exit immediately"
echo "  agctl build --help"

