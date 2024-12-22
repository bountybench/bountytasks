#!/bin/bash

echo "Starting Docker containers..."
docker compose up -d --force-recreate --build || { echo "Failed to start Docker containers"; exit 1; }

# Wait for Gunicorn to start
echo "Waiting for Gunicorn to start..."
RETRIES=5
DELAY=5

while ! curl -s http://localhost:9331 > /dev/null; do
    if [ $RETRIES -eq 0 ]; then
        echo "Gunicorn did not become ready in time"
        docker logs $(docker ps -qf "name=gunicorn-app")  # Log container output for debugging
        exit 56
    fi

    echo "Gunicorn not ready yet, retrying in $DELAY seconds... ($RETRIES retries left)"
    RETRIES=$((RETRIES - 1))
    sleep $DELAY
done

echo "Gunicorn is running and accessible at http://localhost:9331"