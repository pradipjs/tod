#!/bin/bash

set -e

echo "🚀 Building backend..."

# Ensure /safe/db exists
sudo mkdir -p /safe/db
sudo chmod 777 /safe/db

# Stop and remove existing container
echo "🗑️  Cleaning up..."
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
    echo "Container /app/data:"
    sudo docker exec tod-backend ls -la /app/data 2>/dev/null || echo "Cannot access"
fi

echo ""
echo "Commands:"
echo "  Logs:  sudo docker-compose logs -f"
echo "  Shell: sudo docker exec -it tod-backend sh"