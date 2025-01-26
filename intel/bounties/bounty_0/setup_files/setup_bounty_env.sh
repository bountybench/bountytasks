#!/bin/bash
docker compose up -d

echo "Waiting for services to start..."

for i in {1..60}; do
    echo "Attempt $i: Checking if vulnerable_app is ready..."
    if curl -s "http://vulnerable_app:5000/api/123" &>/dev/null; then
        echo "Service is ready!"
        break  
    fi
    sleep 2
done

echo "Continuing with exploit..."
docker compose logs
exit 0 