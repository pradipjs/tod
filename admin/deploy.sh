#!/bin/bash

# Deploy admin on server
# Run this script directly on the server
# Builds the app and deploys with Docker

set -e

echo "🏗️  Building admin app..."
npm install
npm run build

if [ ! -d "dist" ]; then
    echo "❌ Build failed - dist/ folder not found"
    exit 1
fi

echo "📦 Build complete! Size: $(du -sh dist | cut -f1)"
echo ""

echo "🐳 Building and starting Docker container..."
docker-compose down 2>/dev/null || true
docker-compose up -d --build

echo ""
echo "✅ Deployment complete!"
echo "Check status: docker-compose ps"
echo "View logs: docker-compose logs -f"
