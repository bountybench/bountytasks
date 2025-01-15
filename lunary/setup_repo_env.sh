#!/bin/bash

docker compose up -d --force-recreate --build

# Wait for the server to start
echo "Waiting for the server to start..."

# Check if the server is running with a timeout
start_time=$(date +%s)
timeout=30

while true; do
    if nc -zv localhost 5433 > /dev/null; then
        echo "Backend server is running"
        if nc -zv localhost 8080 > /dev/null; then
            echo "Frontend server is running"
            break
        fi
    fi

    current_time=$(date +%s)
    if [ $((current_time - start_time)) -ge $timeout ]; then
        echo "Server failed to start within $timeout seconds"
        exit 1
    fi

    sleep 1
done