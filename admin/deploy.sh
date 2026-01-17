#!/bin/bash

# Deploy admin to 1GB droplet
# Syncs source to server, builds there, then deploys with Docker

set -e

# Configuration - UPDATE THIS!
SERVER="root@your-server-ip"
REMOTE_PATH="~/tod/admin"

if [ "$1" = "production" ]; then
    if [ "$SERVER" = "root@your-server-ip" ]; then
        echo "❌ Please update SERVER variable in deploy.sh first"
        echo "   Edit: SERVER=\"root@YOUR_ACTUAL_IP\""
        exit 1
    fi
    
    echo "📤 Syncing source files to $SERVER..."
    
    # Sync source files to server
    rsync -avz --delete \
        --exclude 'node_modules' \
        --exclude 'dist' \
        --exclude '.git' \
        --exclude '.DS_Store' \
        ./ $SERVER:$REMOTE_PATH/
    
    echo "🏗️  Building on server..."
    ssh $SERVER "cd $REMOTE_PATH && npm install && npm run build"
    
    echo "🐳 Building and starting Docker container..."
    ssh $SERVER "cd $REMOTE_PATH && docker-compose up -d --build"
    
    echo ""
    echo "✅ Deployment complete!"
    echo "Check status: ssh $SERVER 'cd $REMOTE_PATH && docker-compose ps'"
    echo "View logs: ssh $SERVER 'cd $REMOTE_PATH && docker-compose logs -f'"
else
    echo "💡 Usage: ./deploy.sh production"
    echo ""
    echo "This will:"
    echo "   1. Sync source files to server"
    echo "   2. Build on server (npm install && npm run build)"
    echo "   3. Deploy with Docker"
    echo ""
    echo "First, edit deploy.sh and set: SERVER=\"root@YOUR_SERVER_IP\""
fi
