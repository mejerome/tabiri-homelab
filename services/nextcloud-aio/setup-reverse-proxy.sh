#!/bin/bash

# Nextcloud AIO Reverse Proxy Setup Script
# This script helps set up Nextcloud AIO behind Nginx Proxy Manager

set -e

echo "=== Nextcloud AIO Reverse Proxy Setup ==="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if we're in the right directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

print_status "Starting Nginx Proxy Manager..."
cd ../nginx-proxy-manager
docker-compose up -d

# Wait for NPM to start
print_status "Waiting for Nginx Proxy Manager to start..."
sleep 10

print_status "Starting Nextcloud AIO..."
cd ../nextcloud-aio
docker-compose up -d

# Wait for Nextcloud AIO to start
print_status "Waiting for Nextcloud AIO to start..."
sleep 15

# Check if containers are running
print_status "Checking container status..."

NPM_STATUS=$(docker inspect -f '{{.State.Status}}' nginx-proxy-manager 2>/dev/null || echo "not found")
AIO_STATUS=$(docker inspect -f '{{.State.Status}}' nextcloud-aio-mastercontainer 2>/dev/null || echo "not found")

if [ "$NPM_STATUS" = "running" ]; then
    print_status "✓ Nginx Proxy Manager is running"
else
    print_error "✗ Nginx Proxy Manager is not running (status: $NPM_STATUS)"
fi

if [ "$AIO_STATUS" = "running" ]; then
    print_status "✓ Nextcloud AIO Mastercontainer is running"
else
    print_error "✗ Nextcloud AIO Mastercontainer is not running (status: $AIO_STATUS)"
fi

# Test backend connectivity
print_status "Testing backend connectivity..."
if curl -s http://localhost:11000 > /dev/null 2>&1; then
    print_status "✓ Nextcloud AIO backend is accessible on port 11000"
else
    print_error "✗ Cannot reach Nextcloud AIO backend on port 11000"
fi

echo
echo "=== Setup Complete ==="
echo
print_status "Next steps:"
echo "1. Access Nginx Proxy Manager admin at: http://$(hostname -I | awk '{print $1}'):81"
echo "   - Default credentials: admin@example.com / changeme"
echo "2. Create a proxy host for nextcloud.syslogsolution.us pointing to port 11000"
echo "3. Configure SSL certificate in NPM"
echo "4. Access Nextcloud AIO at: https://nextcloud.syslogsolution.us"
echo
print_warning "Don't forget to change the default NPM admin password!"
echo

# Show current status
echo "=== Current Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(nginx-proxy-manager|nextcloud-aio)"

echo
print_status "For detailed instructions, see README.md"
