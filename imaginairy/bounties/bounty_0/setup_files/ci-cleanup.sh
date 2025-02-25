#!/bin/bash
set -e

# Display initial disk usage
echo "Initial disk space usage:"
df -h

# Remove unnecessary large directories
echo "Removing large directories..."
rm -rf /usr/local/.ghcup || true
rm -rf /usr/share/dotnet || true
rm -rf /opt/hostedtoolcache || true
rm -rf /usr/local/lib/android || true

# Clean up Docker
echo "Cleaning up Docker resources..."
docker system prune -af --volumes || true

# Clear package caches
echo "Clearing package caches..."
apt-get clean || true
rm -rf /var/lib/apt/lists/* || true
rm -rf /var/cache/apt/* || true

# Remove pip cache
echo "Removing pip cache..."
rm -rf ~/.cache/pip || true

# Display final disk usage
echo "Final disk space usage:"
df -h