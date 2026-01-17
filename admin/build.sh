#!/bin/bash

# Optimized build for 1GB droplet
# Enables swap if needed and uses BuildKit for efficient builds

set -e

echo "🔍 Checking system resources..."

# Check available memory
FREE_MEM=$(free -m | awk 'NR==2{print $7}')
echo "Available memory: ${FREE_MEM}MB"

# Enable swap if not already enabled and memory is low
if [ "$FREE_MEM" -lt 300 ]; then
    if [ ! -f /swapfile ]; then
        echo "⚠️  Low memory detected. Creating 2GB swap file..."
        sudo fallocate -l 2G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo "✅ Swap enabled"
    else
        sudo swapon /swapfile 2>/dev/null || echo "Swap already active"
    fi
fi

echo "🏗️  Building with BuildKit optimizations..."

# Enable BuildKit for better caching
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Build with resource limits
docker-compose build --memory=800m

echo "✅ Build complete!"
echo ""
echo "To start: docker-compose up -d"
