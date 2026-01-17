#!/bin/bash

# Deploy admin app to 1GB droplet
# Builds locally, then syncs to server

set -e

# Configuration - UPDATE THIS!
SERVER="root@your-server-ip"
REMOTE_PATH="~/tod/admin"

echo "🏗️  Building admin app locally..."
npm run build

if [ ! -d "dist" ]; then
    echo "❌ Build failed - dist/ folder not found"
    exit 1
fi

echo "📦 Build complete!"
echo ""

if [ "$1" = "production" ] && [ "$SERVER" != "root@your-server-ip" ]; then
    echo "🚀 Deploying to server..."
    
    # Sync files to server
    rsync -avz --delete \
        --exclude 'node_modules' \
        --exclude '.git' \
        --exclude 'src' \
        --exclude 'public' \
        ./ $SERVER:$REMOTE_PATH/
    
    echo "🐳 Building and starting Docker container..."
    ssh $SERVER "cd $REMOTE_PATH && docker-compose up -d --build"
    
    echo "✅ Deployment complete!"
else
    echo "💡 Setup:"
    echo "   1. Edit deploy.sh and set SERVER=root@your-server-ip"
    echo "   2. Run: ./deploy.sh production"
fi
