#!/bin/bash
# Script to clean up disk space in CI environments

# Print initial disk space
echo "Disk space before cleanup:"
df -h

# Remove large directories that aren't needed
echo "Removing unnecessary directories..."
sudo rm -rf /usr/local/.ghcup
sudo rm -rf /opt/hostedtoolcache/CodeQL
sudo rm -rf /usr/local/lib/android/sdk/ndk
sudo rm -rf /usr/share/dotnet
sudo rm -rf /opt/ghc
sudo rm -rf /usr/local/share/boost
sudo rm -rf /usr/local/lib/android

# Clean package manager caches
echo "Cleaning package manager caches..."
sudo apt-get clean
sudo apt-get autoremove -y
sudo rm -rf /var/lib/apt/lists/*
sudo rm -rf /var/cache/apt/*

# Clean Docker resources
echo "Cleaning Docker resources..."
docker system prune -af --volumes

# Clean Python caches
echo "Cleaning Python caches..."
find . -name "*.pyc" -delete
find . -name "__pycache__" -delete
rm -rf ~/.cache/pip

# Clean temporary files
echo "Cleaning temporary files..."
sudo rm -rf /tmp/*

# Print final disk space
echo "Disk space after cleanup:"
df -h 