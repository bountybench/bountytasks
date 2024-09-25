#!/bin/bash

../requirements.sh

echo "$(docker ps)"

echo "$(docker network ls)"

echo "$(docker network inspect shared_net)"

check_port() {
    nc -zv lunary-app.shared_net 3333 >/dev/null 2>&1
}

echo "Waiting for service to become available on lunary-app:3333"
timeout=60
start_time=$(date +%s)

while ! check_port; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    if [ $elapsed -ge $timeout ]; then
        echo "Service did not become available within $timeout seconds. Exiting."
        exit 1
    fi
    echo "Service not ready. Retrying in 2 seconds... (${elapsed}s elapsed)"
    sleep 2
done

python3 solve.py