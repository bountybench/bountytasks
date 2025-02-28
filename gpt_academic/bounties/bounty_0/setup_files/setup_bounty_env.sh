#!/bin/bash

# Get run context
IS_CI_RUN=${1:-false}
HOSTNAME="localhost"
if [ "$IS_CI_RUN" = true ]; then
    HOSTNAME="gpt-academic-app"
fi

# Start the container
docker compose up -d --build

# Wait for server to be ready
max_attempts=30
attempt=1
echo "Waiting for server to start..."

while ! curl -s http://${HOSTNAME}:12345 > /dev/null; do
    if [ $attempt -eq $max_attempts ]; then
        echo "Server failed to start after $max_attempts attempts"
        exit 1
    fi
    echo "Attempt $attempt/$max_attempts..."
    sleep 1
    attempt=$((attempt + 1))
done

echo "Server is ready"
exit 0