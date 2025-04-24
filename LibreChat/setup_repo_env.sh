#!/bin/bash
set -e

# Function for cleanup on error
cleanup() {
  echo "An error occurred. Capturing logs for debugging..."
  docker compose logs > setup_error_logs.txt
  echo "Logs saved to setup_error_logs.txt"
}
trap cleanup ERR

# Ensure we have the env file
if [ ! -f "env" ]; then
  echo "env file not found!"
  exit 1
fi

echo "Copying env file to .env"
cp env .env

# Check Docker service
if ! docker info > /dev/null 2>&1; then
  echo "Docker service is not running or not accessible"
  exit 1
fi

# Stop any existing containers and remove them
echo "Stopping any existing containers..."
docker compose down

echo "Starting services with docker compose..."
docker compose up -d --force-recreate --build

HOST="localhost"

# Set timeout variables
start_time=$(date +%s)
timeout=600  # 10 minutes

echo "Waiting for services to be ready..."

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to start and initialize..."
mongo_retry_count=0
mongo_max_retries=60  # 5 minutes at 5-second intervals

while [ $mongo_retry_count -lt $mongo_max_retries ]; do
  # Check if MongoDB container is running
  if ! docker ps | grep -q chat-mongodb; then
    echo "MongoDB container is not running. Checking logs..."
    docker logs chat-mongodb > mongodb_crash.log 2>&1 || true
    echo "Container logs saved to mongodb_crash.log"
    
    echo "Attempting to restart MongoDB container..."
    docker compose restart mongodb
    sleep 10
  fi
  
  # Try to ping MongoDB
  if docker exec chat-mongodb mongosh --quiet --eval "db.runCommand('ping').ok" > /dev/null 2>&1; then
    echo "MongoDB is ready"
    break
  fi
  
  echo -n "."
  sleep 5
  mongo_retry_count=$((mongo_retry_count + 1))
  
  # Every 30 seconds, print more detailed status
  if [ $((mongo_retry_count % 6)) -eq 0 ]; then
    echo ""
    echo "MongoDB still initializing after $((mongo_retry_count * 5)) seconds..."
    docker logs --tail 10 chat-mongodb || true
  fi
  
  if [ $mongo_retry_count -eq $mongo_max_retries ]; then
    echo "MongoDB failed to start within the timeout period"
    echo "Check the container logs for more information."
    exit 1
  fi
done

# Wait for LibreChat API
echo "Waiting for LibreChat API..."
api_retry_count=0
api_max_retries=60  # 5 minutes at 5-second intervals

while [ $api_retry_count -lt $api_max_retries ]; do
  # Check if LibreChat container is running
  if ! docker ps | grep -q librechat; then
    echo "LibreChat container is not running. Checking logs..."
    docker logs librechat > librechat_crash.log 2>&1 || true
    echo "Container logs saved to librechat_crash.log"
    exit 1
  fi
  
  # Try to access the login page
  if curl -s --head --request GET http://$HOST:3080/login | grep "200 OK" > /dev/null; then
    echo "LibreChat API is ready"
    break
  fi
  
  echo -n "."
  sleep 5
  api_retry_count=$((api_retry_count + 1))
  
  # Every 30 seconds, print more detailed status
  if [ $((api_retry_count % 6)) -eq 0 ]; then
    echo ""
    echo "LibreChat API still initializing after $((api_retry_count * 5)) seconds..."
    docker logs --tail 10 librechat || true
  fi
  
  if [ $api_retry_count -eq $api_max_retries ]; then
    echo "LibreChat API failed to start within the timeout period"
    echo "Check the container logs for more information."
    exit 1
  fi
done

# Check all containers are running
echo "Verifying all containers are running..."
for container in librechat chat-mongodb chat-meilisearch vectordb rag_api; do
  if ! docker ps | grep -q $container; then
    echo "$container is not running"
    docker logs $container > ${container}_missing.log 2>&1 || true
    echo "Logs saved to ${container}_missing.log"
    exit 1
  fi
  echo "$container is running"
done

echo "All services are running. Setup completed successfully"
