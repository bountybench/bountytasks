#!/bin/bash
set -e

echo "Disk space before cleanup:"
df -h

# Clean up Docker resources selectively
echo "Cleaning up Docker resources..."

# First, check if the Kali image exists
KALI_IMAGE_EXISTS=$(docker images cybench/kali-linux-ci:latest -q | wc -l)

# Stop and remove containers except running ones
echo "Removing stopped containers..."
docker container prune -f || true

# Remove dangling images (untagged images not referenced by any container)
echo "Removing dangling images..."
docker image prune -f || true

# Remove unused networks (except shared_net)
echo "Removing unused networks except shared_net..."
for network in $(docker network ls --filter "name=^(?!shared_net).*$" --format "{{.Name}}"); do
  if [ "$network" != "shared_net" ] && [ "$network" != "bridge" ] && [ "$network" != "host" ] && [ "$network" != "none" ]; then
    docker network rm $network 2>/dev/null || true
  fi
done

# Clean build cache
echo "Cleaning Docker build cache..."
docker builder prune -f || true

# Remove large directories that aren't needed
echo "Removing unnecessary directories..."
sudo rm -rf /usr/local/.ghcup 2>/dev/null || true
sudo rm -rf /opt/hostedtoolcache/CodeQL 2>/dev/null || true
sudo rm -rf /usr/local/lib/android/sdk/ndk 2>/dev/null || true
sudo rm -rf /usr/share/dotnet 2>/dev/null || true
sudo rm -rf /opt/ghc 2>/dev/null || true
sudo rm -rf /usr/local/share/boost 2>/dev/null || true
sudo rm -rf /usr/local/.ghcup/ghc 2>/dev/null || true

# Clean package manager caches
echo "Cleaning package manager caches..."
sudo apt-get clean 2>/dev/null || true
sudo apt-get autoclean 2>/dev/null || true
sudo apt-get autoremove -y 2>/dev/null || true
sudo rm -rf /var/lib/apt/lists/* 2>/dev/null || true
sudo rm -rf /var/cache/apt/* 2>/dev/null || true

# Clean Python caches
echo "Cleaning Python caches..."
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "__pycache__" -delete 2>/dev/null || true
sudo rm -rf ~/.cache/pip/* 2>/dev/null || true

echo "Disk space after cleanup:"
df -h

# Report if Kali image was preserved
if [ "$KALI_IMAGE_EXISTS" -gt 0 ]; then
  echo "Kali Linux image was preserved."
fi 