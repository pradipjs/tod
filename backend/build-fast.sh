#!/bin/bash

# Fast Docker build script with BuildKit caching
# Uses Docker BuildKit for parallel builds and better caching

set -e

echo "🚀 Building backend with BuildKit optimizations..."

# Enable BuildKit
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Build with cache
docker-compose build --parallel

echo "✅ Build complete!"
echo ""
echo "To start: docker-compose up -d"
