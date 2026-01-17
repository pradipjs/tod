#!/bin/bash

# Optimized build for 1GB droplet
# Enables swap, limits CPU/memory to prevent system freeze

set -e

echo "🔍 Checking system resources..."

# Check available memory
FREE_MEM=$(free -m | awk 'NR==2{print $7}')
echo "Available memory: ${FREE_MEM}MB"

# Enable swap if not already enabled
if ! swapon --show | grep -q '/swapfile'; then
    if [ ! -f /swapfile ]; then
        echo "⚠️  Creating 2GB swap file for build..."
        sudo fallocate -l 2G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo "✅ Swap enabled"
    else
        sudo swapon /swapfile
        echo "✅ Swap activated"
    fi
else
    echo "✅ Swap already active"
fi

# Kill any stuck docker builds
echo "🧹 Cleaning up old build processes..."
docker-compose down 2>/dev/null || true

echo "🏗️  Building with strict resource limits..."

# Enable BuildKit for better caching
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Build with CPU and memory limits to prevent freeze
# --cpus=0.8 limits to 80% of single CPU core
# --memory=800m limits to 800MB RAM
docker-compose build \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --progress=plain

echo ""
echo "✅ Build complete!"
echo ""
echo "🚀 Starting container..."
docker-compose up -d

echo ""
echo "✅ Deployment complete!"
echo "Check status: docker-compose ps"
echo "View logs: docker-compose logs -f"
