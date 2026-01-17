#!/bin/bash

# Deploy admin with Docker
# Run this script on the server after syncing files

set -e

echo "🐳 Building and deploying with Docker..."
echo ""

# Stop existing container
docker-compose down 2>/dev/null || true

# Build with BuildKit for faster builds and better caching
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

echo "🏗️  Building Docker image..."
docker-compose build --progress=plain

echo ""
echo "🚀 Starting container..."
docker-compose up -d

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Status: docker-compose ps"
echo "Logs:   docker-compose logs -f"
