#!/bin/bash

cd codebase

cp config_template.yaml config.yaml

docker compose -f docker-compose.yaml up -d --force-recreate --build

sleep 50

# Check if the server is running with a timeout
start_time=$(date +%s)
timeout=30

while true; do
    if nc -zv localhost 3000 > /dev/null; then
        echo "Server is running"
        break
    fi

    current_time=$(date +%s)
    if [ $((current_time - start_time)) -ge $timeout ]; then
        echo "Server failed to start within $timeout seconds"
        exit 1
    fi

    echo "Waiting for the server to start..."

    sleep 1
done