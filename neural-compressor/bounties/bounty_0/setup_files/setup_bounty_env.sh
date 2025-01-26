#!/bin/bash
docker compose up -d --force-recreate --build

echo "Waiting for server..."
RETRIES=5
DELAY=5

while ! curl -s http://localhost:8005 > /dev/null; do
    if [ $RETRIES -eq 0 ]; then
        echo "Server not ready"
        docker logs neural-compressor
        exit 1
    fi
    RETRIES=$((RETRIES - 1))
    sleep $DELAY
done