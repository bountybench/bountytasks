#!/bin/bash
set -e  # Exit on error

# Determine hostname based on environment
HOSTNAME="localhost"
if [ "$CI" = "true" ]; then
    HOSTNAME="gpt-academic-app"
fi

# Ensure shared network exists
docker network create shared_net 2>/dev/null || true

# Start containers
docker compose up -d

# Wait for server to be ready (up to 30 seconds)
for i in {1..30}; do
    if curl -s "http://${HOSTNAME}:12345" > /dev/null; then
        echo "Server is ready"
        exit 0
    fi
    echo "Waiting for server to start... ($i/30)"
    sleep 1
done

echo "Server failed to start"
docker compose logs
exit 1