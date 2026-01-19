#!/bin/bash

set -e

echo "🚀 Building backend..."

# Ensure /safe/db exists
sudo mkdir -p /safe/db
sudo chmod 777 /safe/db

# Step 1: Kill port 8080 first
PORT=8080
PID=$(sudo lsof -ti:$PORT 2>/dev/null || true)
if [ -n "$PID" ]; then
    echo "🔪 Killing process on port $PORT (PID: $PID)..."
    sudo kill -9 $PID 2>/dev/null || true
    sleep 1
fi

# Step 2: Force kill container process directly
CONTAINER_PID=$(sudo docker inspect --format '{{.State.Pid}}' tod-backend 2>/dev/null || true)
if [ -n "$CONTAINER_PID" ] && [ "$CONTAINER_PID" != "0" ]; then
    echo "🔪 Killing container process (PID: $CONTAINER_PID)..."
    sudo kill -9 $CONTAINER_PID 2>/dev/null || true
    sleep 1
fi

# Step 3: Force remove container (bypass docker stop)
echo "🗑️  Force removing container..."
sudo docker rm -f tod-backend 2>/dev/null || true

# Step 4: Clean up with docker-compose
echo "🧹 Cleaning up docker-compose..."
sudo docker-compose down --remove-orphans 2>/dev/null || true

# Step 5: Remove any dangling volumes
sudo docker volume prune -f 2>/dev/null || true

# Verify configuration before building
echo ""
echo "📋 Verifying docker-compose.yml configuration..."
echo "Volume mount should be: /safe/db:/app/data"
echo "DB_PATH should be: /app/data/truthordare.db"
echo ""
grep -A1 "volumes:" docker-compose.yml | head -2
grep "DB_PATH" docker-compose.yml
echo ""
read -p "Press Enter to continue or Ctrl+C to abort..."

# Build and start
echo "🏗️  Building..."
export DOCKER_BUILDKIT=1
sudo docker-compose build

echo "▶️  Starting..."
sudo docker-compose up -d

# Wait and verify
sleep 5

echo ""
echo "📊 Verifying mount and database..."
echo ""
echo "1️⃣  Host /safe/db contents:"
ls -lah /safe/db/
echo ""
echo "2️⃣  Container /app/data contents:"
sudo docker exec tod-backend ls -lah /app/data/
echo ""
echo "3️⃣  Volume mount info:"
sudo docker inspect tod-backend -f '{{range .Mounts}}{{if eq .Destination "/app/data"}}Source: {{.Source}} -> Dest: {{.Destination}} (Type: {{.Type}}){{end}}{{end}}'
echo ""

echo "📊 Status:"
if [ -f "/safe/db/truthordare.db" ]; then
    echo "✅ Database: /safe/db/truthordare.db"
    ls -lh /safe/db/truthordare.db
else
    echo "❌ Database NOT found at /safe/db/truthordare.db"
    echo ""
    echo "The volume mount is not working!"
    echo "Container created the database but it's not on the host."
    echo ""
    echo "Recent logs:"
    sudo docker-compose logs --tail=15
fi

echo ""
echo "Commands:"
echo "  Logs:  sudo docker-compose logs -f"
echo "  Shell: sudo docker exec -it tod-backend sh"