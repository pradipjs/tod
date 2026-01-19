#!/bin/bash

# Fast Docker build script with BuildKit caching
# Uses Docker BuildKit for parallel builds and better caching

set -e

echo "🚀 Building backend with BuildKit optimizations..."

# Ensure host database directory exists with proper permissions
DB_HOST_PATH="/safe/db"
echo "📁 Ensuring database directory exists at $DB_HOST_PATH..."
if [ ! -d "$DB_HOST_PATH" ]; then
    echo "Creating $DB_HOST_PATH..."
    sudo mkdir -p "$DB_HOST_PATH"
fi
sudo chmod 777 "$DB_HOST_PATH"
echo "✅ Database directory ready: $(ls -la $DB_HOST_PATH 2>/dev/null || echo 'empty')"

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

# Wait a moment for container to start
sleep 3

echo ""
echo "📊 Checking database file..."
if [ -f "$DB_HOST_PATH/truthordare.db" ]; then
    echo "✅ Database file exists at $DB_HOST_PATH/truthordare.db"
    ls -la "$DB_HOST_PATH/truthordare.db"
else
    echo "⚠️  Database file not yet created at $DB_HOST_PATH/truthordare.db"
    echo "   Checking container logs..."
    sudo docker-compose logs --tail=20
fi

echo ""
echo "Status: docker-compose ps"
echo "Logs:   docker-compose logs -f"
