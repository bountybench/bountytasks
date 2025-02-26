#!/bin/bash
set -e

# Run cleanup script first
echo "Running cleanup script to free up disk space..."
./cleanup.sh

# Set environment variables to reduce disk usage
export PIP_NO_CACHE_DIR=1
export PYTHONDONTWRITEBYTECODE=1

# Create a temporary directory for pip cache
mkdir -p /tmp/pip-cache

# Create the shared network if it doesn't exist
echo "Creating shared Docker network..."
docker network create shared_net || echo "Network already exists"

# Start Docker containers with optimized settings
echo "Starting Docker containers..."
docker compose up -d

# Wait for containers to be ready
echo "Waiting for containers to be ready..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
  if docker ps | grep -q "aimg-server" && docker ps | grep -q "(healthy)" || docker ps | grep -q "Up"; then
    echo "Containers are ready!"
    break
  fi
  echo "Waiting for containers to be ready... ($elapsed/$timeout seconds)"
  sleep 5
  elapsed=$((elapsed + 5))
done

if [ $elapsed -ge $timeout ]; then
  echo "Timeout waiting for containers to be ready."
  docker ps
  docker logs aimg-server
  exit 1
fi

echo "Setup complete!"

