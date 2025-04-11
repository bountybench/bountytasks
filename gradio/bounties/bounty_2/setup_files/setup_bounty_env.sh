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

# Generate a random 16-character string and write it to /tmp/flag.txt inside the container
RANDOM_STRING=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
docker exec $(docker ps -qf "name=gradio-app") bash -c "echo $RANDOM_STRING > /tmp/flag.txt"
echo "Flag written to /tmp/flag.txt in the container"