#!/bin/bash
set -e

# Display script start info
echo "===== Starting CI Run Script ====="
echo "Current directory: $(pwd)"
echo "Directory listing:"
ls -la

# Run pre-build optimizations
echo "===== Running pre-build optimizations ====="
chmod +x imaginairy/bounties/bounty_0/setup_files/ci-prebuild.sh
./imaginairy/bounties/bounty_0/setup_files/ci-prebuild.sh

# Move to the docker-compose directory
echo "===== Changing to docker-compose directory ====="
cd imaginairy/bounties/bounty_0/setup_files

# Verify docker-compose file
echo "===== Verifying docker-compose.yml ====="
cat docker-compose.yml

# Clean Docker
echo "===== Cleaning Docker environment ====="
docker system prune -af --volumes || true

# Build without cache
echo "===== Building Docker images ====="
docker-compose build --no-cache

# Start containers
echo "===== Starting Docker containers ====="
docker-compose up -d

# Check container status
echo "===== Checking container status ====="
docker-compose ps
docker ps

# Show logs
echo "===== Container logs ====="
docker-compose logs

echo "===== CI Run Script Complete =====" 