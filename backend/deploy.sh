#!/bin/bash

# Debug and deploy script to fix volume mount issue

set -e

echo "🔍 Debugging volume mount issue..."
echo ""

# Step 1: Check if /safe/db exists and permissions
echo "1️⃣  Checking /safe/db on host:"
if [ -d "/safe/db" ]; then
    ls -lad /safe/db
    echo "   Permissions: $(stat -c '%a %U:%G' /safe/db 2>/dev/null || stat -f '%Lp %Su:%Sg' /safe/db)"
else
    echo "   ❌ /safe/db does not exist!"
    echo "   Creating it..."
    sudo mkdir -p /safe/db
    sudo chmod 777 /safe/db
    ls -lad /safe/db
fi

echo ""
echo "2️⃣  Checking Docker daemon:"
docker info | grep "Storage Driver" || echo "Cannot get Docker info"

echo ""
echo "3️⃣  Stopping any existing containers..."
sudo docker-compose down 2>/dev/null || true
sudo docker stop tod-backend 2>/dev/null || true
sudo docker rm -f tod-backend 2>/dev/null || true

echo ""
echo "4️⃣  Building fresh image..."
sudo docker-compose build --no-cache

echo ""
echo "5️⃣  Starting container with explicit mount..."
sudo docker-compose up -d

echo ""
echo "⏳ Waiting 5 seconds for container to start..."
sleep 5

echo ""
echo "6️⃣  Verifying mount inside container:"
echo ""
echo "   Container /data contents:"
sudo docker exec tod-backend ls -la /data/ || echo "   ❌ Cannot access /data"

echo ""
echo "   Host /safe/db contents:"
ls -la /safe/db/

echo ""
echo "7️⃣  Checking mount information:"
sudo docker inspect tod-backend --format='{{range .Mounts}}Source: {{.Source}} -> Destination: {{.Destination}} (Type: {{.Type}}, RW: {{.RW}}){{println}}{{end}}'

echo ""
echo "8️⃣  Testing write from container:"
sudo docker exec tod-backend sh -c 'echo "test-$(date +%s)" > /data/mount-test.txt && cat /data/mount-test.txt'

echo ""
echo "9️⃣  Checking if test file appears on host:"
if [ -f "/safe/db/mount-test.txt" ]; then
    echo "   ✅ SUCCESS! Mount is working!"
    cat /safe/db/mount-test.txt
    rm -f /safe/db/mount-test.txt
else
    echo "   ❌ FAILED! File not on host"
    echo ""
    echo "   This means Docker is NOT mounting /safe/db to container /data"
    echo ""
    echo "   Possible issues:"
    echo "   - SELinux blocking mount (check: getenforce)"
    echo "   - AppArmor blocking mount (check: aa-status)"
    echo "   - Docker daemon config issue"
    echo "   - Path doesn't exist when Docker starts container"
fi

echo ""
echo "🔟 Container logs:"
sudo docker-compose logs --tail=20

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next steps:"
echo "  - Check logs: sudo docker-compose logs -f"
echo "  - Shell into container: sudo docker exec -it tod-backend sh"
echo "  - Check if DB exists: ls -l /safe/db/truthordare.db"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
