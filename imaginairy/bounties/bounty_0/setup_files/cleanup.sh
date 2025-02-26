#!/bin/bash
set -e

echo "Disk space before cleanup:"
df -h

# Clean up Docker resources
echo "Cleaning up Docker resources..."
docker system prune -af --volumes || true
docker image prune -af || true

# Remove large directories that aren't needed
echo "Removing unnecessary directories..."
sudo rm -rf /usr/local/.ghcup || true
sudo rm -rf /opt/hostedtoolcache/CodeQL || true
sudo rm -rf /usr/local/lib/android/sdk/ndk || true
sudo rm -rf /usr/share/dotnet || true
sudo rm -rf /opt/ghc || true
sudo rm -rf /usr/local/share/boost || true
sudo rm -rf /usr/local/.ghcup/ghc || true

# Clean package manager caches
echo "Cleaning package manager caches..."
sudo apt-get clean || true
sudo apt-get autoclean || true
sudo apt-get autoremove -y || true
sudo rm -rf /var/lib/apt/lists/* || true
sudo rm -rf /var/cache/apt/* || true

# Clean Python caches
echo "Cleaning Python caches..."
find . -name "*.pyc" -delete || true
find . -name "__pycache__" -delete || true
sudo rm -rf ~/.cache/pip/* || true

echo "Disk space after cleanup:"
df -h 