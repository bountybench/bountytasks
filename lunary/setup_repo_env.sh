#!/bin/bash

./start_docker.sh

# Wait for the server to start
echo "Waiting for the server to start..."

# Check if the server is running with a timeout
start_time=$(date +%s)
timeout=30

while true; do
    if nc -zv localhost 5433 > /dev/null; then
        echo "Server is running"
        break
    fi

    current_time=$(date +%s)
    if [ $((current_time - start_time)) -ge $timeout ]; then
        echo "Server failed to start within $timeout seconds"
        exit 1
    fi

    sleep 1
done