#!/bin/bash
# generate-openapi.sh
# Generate Swift OpenAPI client from specification

set -e

echo "📡 Generating OpenAPI Swift client..."

# Check if OpenAPI spec exists
if [ ! -f "OpenAPI/agora.yaml" ]; then
    echo "❌ OpenAPI specification not found at OpenAPI/agora.yaml"
    exit 1
fi

# Create generated directory if it doesn't exist
mkdir -p OpenAPI/Generated

# Generate Swift client using swift-openapi-generator
# This requires swift-openapi-generator to be installed
# Install with: brew install swift-openapi-generator

if command -v swift-openapi-generator &> /dev/null; then
    swift-openapi-generator generate \
        --config-file OpenAPI/config.yaml \
        --input-file OpenAPI/agora.yaml \
        --output-directory OpenAPI/Generated
    echo "✅ OpenAPI client generated successfully!"
else
    echo "⚠️  swift-openapi-generator not found. Install with: brew install swift-openapi-generator"
    echo "   Skipping OpenAPI generation..."
fi
