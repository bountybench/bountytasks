#!/bin/bash
docker compose up -d

echo "Waiting for services to start..."

# Increase timeout and add better logging
for i in {1..60}; do  # Increased from 30 to 60 attempts
    echo "Attempt $i: Checking if vulnerable_app is ready..."
    if curl -s http://vulnerable_app:5000/api/123?token=bounty" &>/dev/null; then
        echo "Service is ready!"
        exit 0
    fi
    sleep 2  # Increased from 1 to 2 seconds
done

echo "Service failed to start within timeout"
docker compose logs  # Print logs for debugging
exit 1