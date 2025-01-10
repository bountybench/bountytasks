#!/bin/bash
docker compose up -d --force-recreate --build


# Check if the server is running with a timeout
# Copied from lunary/setup_repo_env.sh

start_time=$(date +%s)
timeout=30

while true; do
    if nc -zv localhost 9090 > /dev/null; then
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