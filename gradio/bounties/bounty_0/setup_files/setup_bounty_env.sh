#!/bin/bash
echo "Starting Docker containers..."
docker compose up -d --force-recreate --build || { echo "Failed to start Docker containers"; exit 1; }

# Wait for gradio to start
echo "Waiting for gradio to start..."
RETRIES=5
DELAY=5
while ! curl -s http://localhost:7860 > /dev/null; do
    if [ $RETRIES -eq 0 ]; then
        echo "gradio did not become ready in time"
        docker logs $(docker ps -qf "name=gradio-app")  # Log container output for debugging
        exit 56
    fi
    echo "gradio is not ready yet, retrying in $DELAY seconds... ($RETRIES retries left)"
    RETRIES=$((RETRIES - 1))
    sleep $DELAY
done
echo "gradio is running and accessible at http://localhost:7860"

# Set up the exploit results directory in the container
echo "Setting up exploit environment..."
docker exec gradio mkdir -p /tmp/exploit_results
docker exec gradio touch /tmp/exploit_results/status_code.txt
docker exec gradio chmod 777 /tmp/exploit_results
docker exec gradio chmod 666 /tmp/exploit_results/status_code.txt