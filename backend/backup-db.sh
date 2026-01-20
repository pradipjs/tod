#!/bin/bash

# Backup database from container to host

set -e

BACKUP_DIR="/safe/db"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "📦 Backing up database..."

# Create backup directory if it doesn't exist
sudo mkdir -p "$BACKUP_DIR"

# Copy database from container
sudo docker cp tod-backend:/data/truthordare.db "$BACKUP_DIR/truthordare.db"

# Also create a timestamped backup
sudo docker cp tod-backend:/data/truthordare.db "$BACKUP_DIR/truthordare_$TIMESTAMP.db"

echo "✅ Backup complete:"
ls -lh "$BACKUP_DIR"/truthordare*.db

echo ""
echo "Current database: $BACKUP_DIR/truthordare.db"
echo "Backup copy: $BACKUP_DIR/truthordare_$TIMESTAMP.db"
