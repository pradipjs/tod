#!/bin/bash

# Backend Release Script
# This script pulls the latest code, builds a Docker image, and runs the container

set -e

# Navigate to script directory
cd "$(dirname "$0")"

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo -e "${YELLOW}Loading environment from .env file...${NC}"
    export $(grep -v '^#' .env | xargs)
fi

# Configuration
IMAGE_NAME="tod-backend"
CONTAINER_NAME="tod-backend"
PORT="${PORT:-8080}"
DATA_DIR="${DATA_DIR:-$(pwd)/data}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Truth or Dare Backend Release ===${NC}"

# Navigate to script directory
cd "$(dirname "$0")"

# Pull latest code
echo -e "${YELLOW}Pulling latest code...${NC}"
git pull origin main || git pull origin master || echo "Git pull skipped"

# Create data directory if it doesn't exist
echo -e "${YELLOW}Creating data directory...${NC}"
mkdir -p "$DATA_DIR"

# Stop and remove existing container if running
echo -e "${YELLOW}Stopping existing container...${NC}"
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Build Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t "$IMAGE_NAME" .

# Run container
echo -e "${YELLOW}Starting container...${NC}"
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "$PORT:8080" \
    -v "$DATA_DIR:/data" \
    -e APP_ENV="${APP_ENV:-production}" \
    -e OPENAI_API_KEY="${OPENAI_API_KEY}" \
    -e AI_MODEL="${AI_MODEL:-llama-3.3-70b-versatile}" \
    -e AI_API_URL="${AI_API_URL}" \
    -e DB_PATH="/data/truthordare.db" \
    -e CORS_ORIGINS="${CORS_ORIGINS:-http://localhost:3000}" \
    -e LOG_LEVEL="${LOG_LEVEL:-info}" \
    -e SCHEDULER_ENABLED="${SCHEDULER_ENABLED:-true}" \
    "$IMAGE_NAME"

# Wait for container to be healthy
echo -e "${YELLOW}Waiting for container to be healthy...${NC}"
sleep 5

# Check container status
if docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${GREEN}✓ Container is running${NC}"
    echo -e "${GREEN}✓ Backend is available at http://localhost:$PORT${NC}"
    echo -e "${GREEN}✓ Database is stored at $DATA_DIR/truthordare.db${NC}"
    docker logs --tail 10 "$CONTAINER_NAME"
else
    echo -e "${RED}✗ Container failed to start${NC}"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

echo -e "${GREEN}=== Release Complete ===${NC}"
