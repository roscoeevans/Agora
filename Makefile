.PHONY: api-gen api-clean help

# Default target shows available commands
help:
	@echo "Available targets:"
	@echo "  make api-gen    - Generate OpenAPI client code"
	@echo "  make api-clean  - Remove generated code and cached generator"
	@echo "  make help       - Show this help message"

# Generate OpenAPI client code from spec
api-gen:
	@bash Scripts/generate-openapi.sh

# Clean generated code and cached generator
api-clean:
	@echo "🧹 Cleaning OpenAPI generated code and cached generator..."
	@rm -rf Packages/Kits/Networking/Sources/Networking/Generated
	@rm -rf OpenAPI/VERSION.lock
	@rm -rf .tools/swift-openapi-generator
	@echo "✅ Clean complete"

