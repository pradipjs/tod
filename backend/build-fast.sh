#!/bin/bash

# Fast Docker build script with BuildKit caching
# Uses Docker BuildKit for parallel builds and better caching

set -e

echo "🚀 Building backend with BuildKit optimizations..."

# Define paths
DB_HOST_PATH="/safe/db"
DB_FILE="$DB_HOST_PATH/truthordare.db"

# Ensure host database directory exists with proper permissions
echo "📁 Checking database directory at $DB_HOST_PATH..."
if [ ! -d "$DB_HOST_PATH" ]; then
    echo "⚠️  Creating $DB_HOST_PATH..."
    sudo mkdir -p "$DB_HOST_PATH"
fi

# Set permissions
echo "🔒 Setting permissions on $DB_HOST_PATH..."
sudo chmod 777 "$DB_HOST_PATH"

# Show current state
echo "✅ Database directory ready:"
ls -la "$DB_HOST_PATH"

# Force stop and remove existing container
echo ""
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
echo "▶️  Starting container..."
sudo docker-compose up -d

# Wait for container to initialize
echo ""
echo "⏳ Waiting for container to initialize..."
sleep 5

echo ""
echo "🔍 Verifying volume mount..."
MOUNT_INFO=$(sudo docker inspect tod-backend -f '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null || echo "ERROR: Could not inspect container")
echo "$MOUNT_INFO"

echo ""
echo "📊 Checking database file..."
if [ -f "$DB_FILE" ]; then
    echo "✅ SUCCESS: Database file exists at $DB_FILE"
    ls -lh "$DB_FILE"
else
    echo "❌ ERROR: Database file NOT found at $DB_FILE"
    echo ""
    echo "📁 Contents of $DB_HOST_PATH:"
    ls -la "$DB_HOST_PATH"
    echo ""
    echo "🐳 Checking container's /data directory:"
    sudo docker exec tod-backend ls -la /data || echo "ERROR: Could not list /data in container"
    echo ""
    echo "📋 Recent container logs:"
    sudo docker-compose logs --tail=30
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Status: sudo docker-compose ps"
echo "Logs:   sudo docker-compose logs -f"
echo "Shell:  sudo docker exec -it tod-backend sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
