#!/bin/bash

set -e

echo "🚀 Deploying backend..."

# Create data directory if it doesn't exist
echo "📁 Setting up data directory..."
sudo mkdir -p /home/tod-data
sudo chmod 755 /home/tod-data

# Stop and remove existing container
echo "🛑 Stopping existing container..."

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

# Build with BuildKit for faster builds and better caching
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

echo "🏗️  Building Docker image..."
sudo docker-compose build --progress=plain

echo ""
echo "🚀 Starting container..."

# Final cleanup before starting
CONTAINER_PID=$(sudo docker inspect --format '{{.State.Pid}}' tod-backend 2>/dev/null || true)
if [ -n "$CONTAINER_PID" ] && [ "$CONTAINER_PID" != "0" ]; then
    echo "⚠️  Killing remaining container process (PID: $CONTAINER_PID)"
    sudo kill -9 $CONTAINER_PID 2>/dev/null || true
    sleep 1
fi
sudo docker rm -f tod-backend 2>/dev/null || true

# Start container
sudo docker-compose up -d

# Wait for startup
sleep 3

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 Status:"
sudo docker-compose ps

echo ""
echo "📝 Check logs: sudo docker-compose logs -f"
echo "🔍 Check database: ls -la /home/tod-data/"
