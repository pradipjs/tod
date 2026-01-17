#!/bin/bash

# Deploy admin with Docker
# Run this script on the server after syncing files

set -e

echo "🐳 Building and deploying with Docker..."
echo ""

# Force stop and remove existing container
echo "🗑️  Cleaning up existing container..."

# Get container PID and kill process
CONTAINER_PID=$(sudo docker inspect --format '{{.State.Pid}}' tod-admin 2>/dev/null || true)
if [ -n "$CONTAINER_PID" ] && [ "$CONTAINER_PID" != "0" ]; then
    echo "⚠️  Killing container process (PID: $CONTAINER_PID)"
    sudo kill -9 $CONTAINER_PID 2>/dev/null || true
    sleep 1
fi

# Remove container and cleanup
sudo docker rm -f tod-admin 2>/dev/null || true
sudo docker-compose down --remove-orphans 2>/dev/null || true

# Kill any remaining process using port 3000
PORT=${PORT:-3000}
PID=$(sudo lsof -ti:$PORT 2>/dev/null || true)
if [ -n "$PID" ]; then
    echo "⚠️  Killing process on port $PORT (PID: $PID)"
    sudo kill -9 $PID 2>/dev/null || true
    sleep 1
fi

# Build with BuildKit for faster builds and better caching
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

echo "🏗️  Building Docker image..."
docker-compose build --progress=plain

echo ""
echo "🚀 Starting container..."

# Final cleanup before starting
CONTAINER_PID=$(sudo docker inspect --format '{{.State.Pid}}' tod-admin 2>/dev/null || true)
if [ -n "$CONTAINER_PID" ] && [ "$CONTAINER_PID" != "0" ]; then
    echo "⚠️  Killing remaining container process (PID: $CONTAINER_PID)"
    sudo kill -9 $CONTAINER_PID 2>/dev/null || true
    sleep 1
fi
sudo docker rm -f tod-admin 2>/dev/null || true

# Start container
sudo docker-compose up -d

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Status: docker-compose ps"
echo "Logs:   docker-compose logs -f"
