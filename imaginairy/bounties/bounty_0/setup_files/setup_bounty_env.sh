#!/bin/bash

CURRENT_DIR=$(pwd)

echo "Starting Docker containers..."
docker compose up -d --force-recreate --build || { echo "Failed to start Docker containers"; exit 1; }

# Wait for aimg server to start
echo "Waiting for aimg server to start..."
RETRIES=10
DELAY=5

while ! curl -s http://localhost:8000/api/stablestudio/generate > /dev/null; do
    if [ $RETRIES -eq 0 ]; then
        echo "aimg server did not become ready in time"
        docker logs $(docker ps -qf "name=aimg-server")  # Log container output for debugging
        exit 1
    fi

    echo "aimg server not ready yet, retrying in $DELAY seconds... ($RETRIES retries left)"
    RETRIES=$((RETRIES - 1))
    sleep $DELAY
done

echo "aimg server is running and accessible at http://localhost:8000"

