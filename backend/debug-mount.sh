#!/bin/bash

# Manual debug commands - run these one by one on your server

echo "=== 1. Check if /safe/db exists and permissions ==="
ls -lad /safe/db
stat /safe/db
echo ""

echo "=== 2. Check what's inside /safe/db on host ==="
ls -la /safe/db/
echo ""

echo "=== 3. Check if container is running ==="
docker ps | grep tod-backend
echo ""

echo "=== 4. Check container mount configuration ==="
docker inspect tod-backend --format='{{json .Mounts}}' | python3 -m json.tool 2>/dev/null || docker inspect tod-backend --format='{{json .Mounts}}'
echo ""

echo "=== 5. Check what's inside container /data ==="
docker exec tod-backend ls -la /data/
echo ""

echo "=== 6. Test: Create file on HOST and check if visible in CONTAINER ==="
echo "test-from-host-$(date +%s)" | sudo tee /safe/db/test-host.txt
echo "File created on host. Now checking in container..."
docker exec tod-backend cat /data/test-host.txt 2>/dev/null && echo "✅ File visible in container!" || echo "❌ File NOT visible in container"
echo ""

echo "=== 7. Test: Create file in CONTAINER and check if visible on HOST ==="
docker exec tod-backend sh -c 'echo "test-from-container-$(date +%s)" > /data/test-container.txt'
echo "File created in container. Now checking on host..."
cat /safe/db/test-container.txt 2>/dev/null && echo "✅ File visible on host!" || echo "❌ File NOT visible on host"
echo ""

echo "=== 8. Check docker-compose config ==="
docker-compose config | grep -A10 volumes
echo ""

echo "=== 9. Check SELinux status (if applicable) ==="
getenforce 2>/dev/null || echo "SELinux not installed"
echo ""

echo "=== 10. Check AppArmor status (if applicable) ==="
aa-status 2>/dev/null || echo "AppArmor not installed"
echo ""

echo "=== 11. Check Docker storage driver ==="
docker info | grep -i "storage driver"
echo ""

echo "=== 12. Check container process and filesystem ==="
docker exec tod-backend df -h | grep /data
echo ""

echo "=== 13. Cleanup test files ==="
sudo rm -f /safe/db/test-host.txt /safe/db/test-container.txt 2>/dev/null
docker exec tod-backend rm -f /data/test-host.txt /data/test-container.txt 2>/dev/null
echo "Test files cleaned up"
