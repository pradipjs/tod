#!/bin/bash

# Simple deploy and backup script

set -e

echo "🚀 Deploying backend..."

# Stop and remove
sudo docker-compose down 2>/dev/null || true
sudo docker rm -f tod-backend 2>/dev/null || true

# Build and start
sudo docker-compose build
sudo docker-compose up -d

# Wait for startup
sleep 5

echo ""
echo "📊 Status:"
sudo docker-compose ps

echo ""
echo "📦 Database location:"
echo "Inside container: /data/truthordare.db"
echo ""
echo "To backup database to host:"
echo "  sudo docker cp tod-backend:/data/truthordare.db /safe/db/truthordare.db"
echo ""
echo "To restore database from host:"
echo "  sudo docker cp /safe/db/truthordare.db tod-backend:/data/truthordare.db"
echo ""
echo "To access database directly:"
echo "  sudo docker exec -it tod-backend sqlite3 /data/truthordare.db"
echo ""
echo "Logs: sudo docker-compose logs -f"
