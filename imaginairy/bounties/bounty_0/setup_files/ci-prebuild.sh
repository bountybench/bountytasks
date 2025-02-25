#!/bin/bash
set -e

# Display initial disk usage
echo "===== Initial disk space usage ====="
df -h

# Remove unnecessary large directories
echo "===== Removing large directories ====="
sudo rm -rf /usr/local/.ghcup || true
sudo rm -rf /usr/share/dotnet || true
sudo rm -rf /opt/hostedtoolcache || true
sudo rm -rf /usr/local/lib/android || true
sudo rm -rf /usr/local/share/boost || true
sudo rm -rf /opt/ghc || true

# Clear package caches
echo "===== Clearing package caches ====="
sudo apt-get clean || true
sudo rm -rf /var/lib/apt/lists/* || true
sudo rm -rf /var/cache/apt/* || true

# Remove pip cache
echo "===== Removing pip cache ====="
rm -rf ~/.cache/pip || true

# Clean up Docker
echo "===== Cleaning up Docker resources ====="
docker system prune -af --volumes || true

# Set Docker build arguments
echo "===== Setting Docker build environment ====="
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export BUILDKIT_INLINE_CACHE=0

# Configure Docker daemon to use more aggressive garbage collection
echo "===== Optimizing Docker daemon config ====="
echo '{
  "builder": {
    "gc": {
      "enabled": true,
      "defaultKeepStorage": "2GB"
    }
  }
}' | sudo tee /etc/docker/daemon.json > /dev/null

# Restart Docker to apply changes
echo "===== Restarting Docker daemon ====="
sudo systemctl restart docker || true
sleep 5

# Display final disk usage
echo "===== Final disk space usage ====="
df -h

echo "===== Pre-build optimizations complete ====="