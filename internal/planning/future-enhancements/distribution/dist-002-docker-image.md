# [Distribution] Docker Image

## Overview
Create a Docker image for the GitHub Project AI Manager that provides a consistent, isolated environment for running the tool. This enables use in CI/CD pipelines, containerized workflows, and systems where local installation isn't preferred.

## Task Classification
- **Type**: Enhancement
- **Risk Level**: Medium
- **Effort**: Medium
- **Dependencies**: foundation-002 (installation script), dev-002 (quality tools for build process)

## Acceptance Criteria
- [ ] Multi-stage Dockerfile for optimized image size
- [ ] Alpine Linux base for minimal footprint
- [ ] All dependencies pre-installed (GitHub CLI, jq)
- [ ] GitHub authentication support via environment variables
- [ ] Volume mounting for project configuration
- [ ] Docker Compose example for easy setup
- [ ] Multi-architecture support (AMD64, ARM64)
- [ ] Automated builds via GitHub Actions
- [ ] Published to Docker Hub and GitHub Container Registry
- [ ] Image security scanning integration
- [ ] Documentation and usage examples

## Technical Specification

### Dockerfile Structure
```dockerfile
# Multi-stage build for minimal final image
FROM alpine:3.18 AS builder

# Install build dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    git

# Install GitHub CLI
RUN curl -sSL https://github.com/cli/cli/releases/latest/download/gh_*_linux_amd64.tar.gz \
    | tar -xz -C /tmp \
    && mv /tmp/gh_*/bin/gh /usr/local/bin/

# Copy and validate project files
COPY . /app
WORKDIR /app
RUN chmod +x github-pm scripts/*.sh

# Validate installation
RUN ./github-pm --version

# Final minimal image
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    git

# Copy GitHub CLI from builder
COPY --from=builder /usr/local/bin/gh /usr/local/bin/

# Copy application
COPY --from=builder /app /opt/github-pm

# Create symlink for global access
RUN ln -s /opt/github-pm/github-pm /usr/local/bin/github-pm

# Create workspace directory
WORKDIR /workspace

# Set up entrypoint
ENTRYPOINT ["github-pm"]
CMD ["help"]

# Metadata
LABEL org.opencontainers.image.title="GitHub Project AI Manager"
LABEL org.opencontainers.image.description="AI-friendly GitHub Project Management CLI"
LABEL org.opencontainers.image.source="https://github.com/username/github-pm"
LABEL org.opencontainers.image.licenses="MIT"
```

### Docker Compose Setup
```yaml
# docker-compose.yml
version: '3.8'

services:
  github-pm:
    image: github-pm:latest
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
    volumes:
      - ./project-config:/workspace/config
      - ./output:/workspace/output
    working_dir: /workspace
    command: ["status", "--format=json"]

  # Development service with source mounting
  github-pm-dev:
    build: .
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
    volumes:
      - .:/workspace
      - ./project-info.json:/workspace/project-info.json
    working_dir: /workspace
    command: ["doctor"]
```

### Multi-Architecture Build
```yaml
# .github/workflows/docker.yml
name: Build Docker Image

on:
  push:
    tags: ['v*']
  pull_request:
    branches: ['main']

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
        
      - name: Login to Docker Hub
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
          
      - name: Login to GitHub Container Registry
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
          
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: |
            username/github-pm
            ghcr.io/username/github-pm
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Usage Examples

#### Basic Usage
```bash
# Pull the image
docker pull username/github-pm:latest

# Run with authentication
docker run --rm \
  -e GITHUB_TOKEN="$GITHUB_TOKEN" \
  -v $(pwd):/workspace \
  username/github-pm:latest doctor

# Interactive session
docker run -it --rm \
  -e GITHUB_TOKEN="$GITHUB_TOKEN" \
  -v $(pwd):/workspace \
  username/github-pm:latest bash
```

#### CI/CD Integration
```yaml
# Example GitHub Action using Docker image
- name: Setup Project
  run: |
    docker run --rm \
      -e GITHUB_TOKEN="${{ secrets.GITHUB_TOKEN }}" \
      -v ${{ github.workspace }}:/workspace \
      username/github-pm:latest setup-complete --dry-run
```

#### Development Environment
```bash
# Start development environment
docker-compose up github-pm-dev

# Run specific commands
docker-compose run github-pm-dev discover --format=json
```

## Testing Strategy

### Image Testing
- Test on multiple architectures (AMD64, ARM64)
- Validate all dependencies are working
- Test GitHub authentication methods
- Verify volume mounting and permissions

### Security Testing
- Scan images for vulnerabilities
- Test with minimal required permissions
- Validate secret handling
- Test isolation and sandboxing

### Integration Testing
- Test in various CI/CD systems
- Validate with different Docker versions
- Test networking and file system access
- Performance testing for large projects

## Documentation Impact
- Add Docker installation section to README.md
- Create Docker usage guide in docs/
- Add CI/CD integration examples
- Document security best practices

## Security Considerations
- Regular base image updates
- Vulnerability scanning
- Minimal attack surface
- Secure secret handling
- Non-root user execution
- Read-only file system where possible

## Implementation Notes
- Keep image size minimal (< 100MB)
- Support offline operation where possible
- Clear error messages for common issues
- Provide both latest and versioned tags
- Include health check for container orchestration