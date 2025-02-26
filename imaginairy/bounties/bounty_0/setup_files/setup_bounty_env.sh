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

# Detect available CPUs and adjust docker-compose.yml if needed
AVAILABLE_CPUS=$(nproc)
echo "Available CPUs: $AVAILABLE_CPUS"

if [ -f "docker-compose.yml" ]; then
  # Check if docker-compose.yml has a CPU limit higher than available
  CPU_LIMIT=$(grep -oP 'cpus: \K[0-9.]+' docker-compose.yml || echo "0")
  
  # Simple integer comparison as fallback
  if [ -n "$CPU_LIMIT" ] && [ "$CPU_LIMIT" -gt "$AVAILABLE_CPUS" ]; then
    echo "Adjusting CPU limit from $CPU_LIMIT to $AVAILABLE_CPUS in docker-compose.yml"
    # Use sed to replace the CPU limit
    sed -i "s/cpus: '[0-9.]\+'/cpus: '$AVAILABLE_CPUS'/g" docker-compose.yml
  fi
  
  # Check for storage_opt and remove it if present
  if grep -q "storage_opt:" docker-compose.yml; then
    echo "Removing storage_opt from docker-compose.yml as it's not supported in this environment"
    # Use sed to remove storage_opt and its indented content
    sed -i '/storage_opt:/,/^[[:space:]]*[^[:space:]]/s/^[[:space:]]*storage_opt:.*//g' docker-compose.yml
    sed -i '/size:/s/^[[:space:]]*size:.*//g' docker-compose.yml
    # Clean up empty lines
    sed -i '/^[[:space:]]*$/d' docker-compose.yml
  fi
fi

# Start Docker containers with optimized settings
echo "Starting Docker containers..."
docker compose up -d

# Wait for containers to be ready
echo "Waiting for containers to be ready..."
timeout=60
elapsed=0
container_started=false

while [ $elapsed -lt $timeout ]; do
  # Check if container exists and is running (regardless of health status)
  if docker ps | grep -q "aimg-server"; then
    container_status=$(docker inspect --format='{{.State.Status}}' aimg-server 2>/dev/null)
    health_status=$(docker inspect --format='{{.State.Health.Status}}' aimg-server 2>/dev/null || echo "none")
    
    echo "Container status: $container_status, Health status: $health_status"
    
    # If container is running, consider it ready regardless of health status
    # For DoS testing, we just need the container to be running
    if [ "$container_status" = "running" ]; then
      echo "Container is running. Proceeding with tests..."
      container_started=true
      break
    fi
  else
    echo "Container not found in running containers list"
    docker ps
  fi
  
  echo "Waiting for containers to be ready... ($elapsed/$timeout seconds)"
  sleep 5
  elapsed=$((elapsed + 5))
done

if [ "$container_started" = false ]; then
  echo "Timeout waiting for containers to be ready."
  docker ps
  docker logs aimg-server
  exit 1
fi

# Give the server a few more seconds to initialize
echo "Container is running. Waiting 10 more seconds for server initialization..."
sleep 10

echo "Setup complete!"

