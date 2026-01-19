#!/bin/bash

set -e

echo "🚀 Building backend..."

# Ensure /safe/db exists
sudo mkdir -p /safe/db
sudo chmod 777 /safe/db

# Kill port 8080 first
PORT=8080
PID=$(sudo lsof -ti:$PORT 2>/dev/null || true)
if [ -n "$PID" ]; then
    echo "🗑️  Killing process on port $PORT (PID: $PID)..."
    sudo kill -9 $PID 2>/dev/null || true
    sleep 2
fi

# Force kill container process
CONTAINER_PID=$(sudo docker inspect --format '{{.State.Pid}}' tod-backend 2>/dev/null || true)
if [ -n "$CONTAINER_PID" ] && [ "$CONTAINER_PID" != "0" ]; then
    echo "🗑️  Killing container process (PID: $CONTAINER_PID)..."
    sudo kill -9 $CONTAINER_PID 2>/dev/null || true
    sleep 2
fi

# Stop and remove existing container
echo "🗑️  Cleaning up containers..."
sudo docker-compose down 2>/dev/null || true
sudo docker rm -f tod-backend 2>/dev/null || true

# Build and start
echo "🏗️  Building..."
export DOCKER_BUILDKIT=1
sudo docker-compose build

echo "▶️  Starting..."
sudo docker-compose up -d

# Wait and verify
sleep 5

echo ""
echo "📊 Status:"
if [ -f "/safe/db/truthordare.db" ]; then
    echo "✅ Database: /safe/db/truthordare.db"
    ls -lh /safe/db/truthordare.db
else
    echo "⚠️  Database not found at /safe/db/truthordare.db"
    echo "Checking container /app/data:"
    sudo docker exec tod-backend ls -la /app/data 2>/dev/null || echo "Cannot access /app/data"
    echo ""
    echo "Recent logs:"
    sudo docker-compose logs --tail=15
fi

echo ""
echo "Commands:"
echo "  Logs:  sudo docker-compose logs -f"
echo "  Shell: sudo docker exec -it tod-backend sh"