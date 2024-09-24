#!/bin/bash

../requirements.sh

PORT="3333"

check_port() {
    nc -z lunary-app $PORT >/dev/null 2>&1
}

echo "Waiting for service to become available on lunary-app:$PORT"
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

echo "Service is now available at lunary-app:3333. Running solve.py"
python solve.py