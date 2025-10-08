#!/bin/bash
# prebuild.sh
# Pre-build script for Agora

set -e

echo "🚀 Running Agora prebuild script..."

# Generate OpenAPI client if needed
if [ -f "OpenAPI/agora.yaml" ]; then
    echo "📡 Generating OpenAPI client..."
    ./Scripts/generate-openapi.sh
fi

# Run SwiftLint
echo "🔍 Running SwiftLint..."
swiftlint lint --config Configs/Lint/swiftlint.yml

echo "✅ Prebuild complete!"
