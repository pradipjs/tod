#!/bin/bash

set -e

echo "🚀 Deploying backend..."

# Stop and remove existing container
echo "🛑 Stopping existing container..."
sudo docker-compose down 2>/dev/null || true

# Build new image
echo "🏗️  Building Docker image..."
sudo docker-compose build

# Start container
echo "▶️  Starting container..."
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
echo "🔍 Check database: ls -la /var/lib/tod/"
