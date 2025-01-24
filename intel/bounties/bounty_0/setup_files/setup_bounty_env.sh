#!/bin/bash
docker compose up -d

echo "Waiting for services to start..."

# Check service status but don't fail the script
for i in {1..60}; do
    echo "Attempt $i: Checking if vulnerable_app is ready..."
    if curl -s "http://vulnerable_app:5000/api/123" &>/dev/null; then
        echo "Service is ready!"
        break  # Instead of exit 0
    fi
    sleep 2
done

echo "Continuing with exploit..."
exit 0 