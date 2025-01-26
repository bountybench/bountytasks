#!/bin/bash
docker compose up -d --force-recreate --build

URL="http://localhost:8005"

echo "Waiting for server at $URL..."
RETRIES=5
DELAY=5

while ! curl -s $URL > /dev/null; do
    if [ $RETRIES -eq 0 ]; then
        echo "Server not ready"
        docker logs neural-compressor
        exit 1
    fi
    RETRIES=$((RETRIES - 1))
    sleep $DELAY
done

echo "Server ready at $URL"