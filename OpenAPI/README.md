# OpenAPI Specification

This directory contains the OpenAPI specification for the Agora API and related code generation configuration.

## Files

### `agora.yaml`
The OpenAPI 3.0 specification defining all API endpoints, request/response schemas, and authentication. This is the **source of truth** for the API contract between client and server.

### `openapi-config.yaml`
Configuration for the Swift OpenAPI code generator, specifying:
- Access modifiers (public)
- Sendable conformance
- Async/await support
- Output directory
- Generation options

### `VERSION.lock`
Records the version of `swift-openapi-generator` that successfully compiled on this system. This ensures consistent generation across the team and CI.

**Note**: This file is auto-generated on first run and should be committed.

## Generated Code

Generated Swift client code is placed in:
```
../Packages/Kits/Networking/Sources/Networking/Generated/
```

⚠️ **Important**: Generated code is **committed to version control** (not gitignored). This ensures:
- Fast builds (no generation at build time)
- Reproducible builds
- Code review visibility
- No SPM plugin compatibility issues with Swift 6.2

## Usage

### Generate Client Code

From the repository root:

```bash
# Generate Swift client from OpenAPI spec
make api-gen

# Clean generated code and cached generator
make api-clean
```

### Workflow

1. **Edit the spec**: Update `agora.yaml` with new endpoints or changes
2. **Generate code**: Run `make api-gen`
3. **Review changes**: Use `git diff` to see what changed
4. **Update implementations**: Wire new endpoints into `OpenAPIAgoraClient`
5. **Commit everything**: Commit spec + generated code + VERSION.lock together

### CI Integration

Add this check to your CI pipeline to ensure generated code stays in sync:

```bash
make api-gen
git diff --exit-code Packages/Kits/Networking/Sources/Networking/Generated || \
  (echo "❌ OpenAPI spec changed but generated code wasn't updated" && exit 1)
```

## Editing the Spec

### Best Practices

1. **Use refs for reusable schemas**: Define common types in `components/schemas` and reference them
2. **Document everything**: Add descriptions to endpoints, parameters, and schemas
3. **Version carefully**: Use semantic versioning in `info.version`
4. **Validate before committing**: Use an OpenAPI validator (VS Code extensions available)

### Adding a New Endpoint

Example: Adding a new POST endpoint

```yaml
paths:
  /posts:
    post:
      summary: Create a new post
      tags: [Posts]
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreatePostRequest'
      responses:
        '201':
          description: Post created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Post'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'

components:
  schemas:
    CreatePostRequest:
      type: object
      required:
        - text
      properties:
        text:
          type: string
          maxLength: 70
        linkUrl:
          type: string
          format: uri
```

### Common Schema Types

```yaml
components:
  schemas:
    # UUID identifier
    id:
      type: string
      format: uuid
    
    # Timestamp
    timestamp:
      type: string
      format: date-time
    
    # Pagination
    PaginatedResponse:
      type: object
      required:
        - items
        - nextCursor
      properties:
        items:
          type: array
          items:
            $ref: '#/components/schemas/YourItem'
        nextCursor:
          type: string
          nullable: true
```

## Configuration Options

The `openapi-config.yaml` controls code generation behavior:

### Current Settings

```yaml
generation:
  accessModifier: public              # Make types public for use in features
  addSendableConformance: true        # Required for Swift 6.2
  asyncClient: true                   # Use async/await (not callbacks)
  concurrency:
    useActors: true                   # Use actors for thread safety
  useURLSessionConfiguration: true    # Allow custom URLSession config

output:
  paths:
    sources: "../Packages/Kits/Networking/Sources/Networking/Generated"

options:
  stableFileNames: true               # Consistent names for git diffs
  datesAsISO8601: true                # Parse dates as ISO 8601 strings
```

### Modifying Configuration

After changing config:
1. Run `make api-clean` to clear cached state
2. Run `make api-gen` to regenerate with new settings
3. Review and test changes
4. Commit config + generated code together

## Version Management

### Locked Version

The generator version is locked after first successful build:
```
OpenAPI/VERSION.lock
```

This prevents version drift across developers and CI.

### Upgrading Generator

To upgrade to a newer version:

```bash
# Clean cached generator
make api-clean

# Edit Scripts/generate-openapi.sh to add new version to CANDIDATES array
# Put the desired version first in the list

# Regenerate - will try new version first
make api-gen

# If successful, VERSION.lock will update
# Commit the new VERSION.lock
```

### Downgrading

To force a specific version:
```bash
echo "1.5.0" > OpenAPI/VERSION.lock
make api-clean
make api-gen
```

## Troubleshooting

### Generation Fails

**Problem**: Script exits with "No swift-openapi-generator version compiled"

**Solutions**:
1. Check Swift version: `swift --version` (need 6.2+)
2. Try clean build: `make api-clean && make api-gen`
3. Check script output for specific compiler errors

### Invalid Spec

**Problem**: Generation fails with OpenAPI validation errors

**Solutions**:
1. Validate spec online: [Swagger Editor](https://editor.swagger.io/)
2. Use VS Code extension: "OpenAPI (Swagger) Editor"
3. Check for typos in `$ref` paths
4. Ensure all refs point to existing schemas

### Import Errors in Generated Code

**Problem**: Generated code has missing imports

**Solutions**:
1. Ensure all required packages are in `Networking/Package.swift`:
   - `OpenAPIRuntime`
   - `OpenAPIURLSession`
   - `HTTPTypes`
2. Check `openapi-config.yaml` settings
3. Try regenerating: `make api-clean && make api-gen`

## Resources

- [OpenAPI 3.0 Specification](https://swagger.io/specification/)
- [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator)
- [Swift OpenAPI Generator Docs](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation)
- [Agora API Blueprint](../docs/agora-mvp-blueprint.md)

## Related Files

- [Networking Kit README](../Packages/Kits/Networking/README.md) - How to use generated client
- [Scripts/generate-openapi.sh](../Scripts/generate-openapi.sh) - Generation script
- [Makefile](../Makefile) - Convenience commands

