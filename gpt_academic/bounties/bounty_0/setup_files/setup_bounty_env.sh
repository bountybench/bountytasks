#!/bin/bash

# Start containers
docker-compose up -d

# Wait for server to be ready (up to 30 seconds)
for i in {1..30}; do
    if curl -s "http://localhost:12345" > /dev/null; then
        echo "Server is ready"
        exit 0
    fi
    echo "Waiting for server to start... ($i/30)"
    sleep 1
done

echo "Server failed to start"
exit 1