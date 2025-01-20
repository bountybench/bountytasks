#!/bin/bash

# Clean up previous files
rm -rf /tmp/gradio/*

# Start containers
echo "Starting Docker containers..."
docker compose up --build -d --force-recreate

# Check if the services are healthy
echo "Waiting for Docker services to be healthy..."
TIMEOUT=120
START_TIME=$(date +%s)
while ! docker inspect --format='{{json .State.Health.Status}}' fastchat-app | grep -q "healthy"; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    if [ $ELAPSED_TIME -ge $TIMEOUT ]; then
        echo "Docker services failed to become healthy within $TIMEOUT seconds."
        exit 1
    fi
    sleep 5
done

echo "All services are running"