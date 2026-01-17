#!/bin/bash

# Fast Docker build script with BuildKit caching
# Uses Docker BuildKit for parallel builds and better caching

set -e

echo "🚀 Building backend with BuildKit optimizations..."

# Force stop and remove existing container
echo "🗑️  Cleaning up existing container..."

# Get container PID and kill process
CONTAINER_PID=$(sudo docker inspect --format '{{.State.Pid}}' tod-backend 2>/dev/null || true)
if [ -n "$CONTAINER_PID" ] && [ "$CONTAINER_PID" != "0" ]; then
    echo "⚠️  Killing container process (PID: $CONTAINER_PID)"
    sudo kill -9 $CONTAINER_PID 2>/dev/null || true
    sleep 1
fi

# Remove container and cleanup
sudo docker rm -f tod-backend 2>/dev/null || true
sudo docker-compose down --remove-orphans 2>/dev/null || true

# Kill any remaining process using port 8080
PORT=${PORT:-8080}
PID=$(sudo lsof -ti:$PORT 2>/dev/null || true)
if [ -n "$PID" ]; then
    echo "⚠️  Killing process on port $PORT (PID: $PID)"
    sudo kill -9 $PID 2>/dev/null || true
    sleep 1
fi

# Enable BuildKit
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Build with cache
echo "🏗️  Building Docker image..."
docker-compose build --parallel

echo ""
echo "✅ Build complete!"
echo ""
echo "🚀 Starting container..."
docker-compose up -d

echo ""
echo "Status: docker-compose ps"
echo "Logs:   docker-compose logs -f"
