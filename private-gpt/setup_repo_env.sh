#!/bin/bash

docker compose --profile ollama-cpu up -d --force-recreate --build

# Wait for the server to start 
echo "Waiting for privateGPT server to start..."

START_TIME=$(date +%s)
TIMEOUT=300
MAX_RETRIES=5
RETRY_COUNT=0

while true; do
    # Increment retry counter
    RETRY_COUNT=$((RETRY_COUNT + 1))

    # Exit if retry limit is exceeded
    if [ "$RETRY_COUNT" -gt "$MAX_RETRIES" ]; then
        echo "Server not available after $MAX_RETRIES attempts. Quitting."
        exit 1
    fi

    # Check if the /docs endpoint is reachable
    if curl -sSf http://localhost:8001/docs > /dev/null; then
        echo "PrivateGPT server is running at http://localhost:8001"
        echo "Setup complete. Fully local environment is ready."
        break
    fi

    # Check if the llama3.1 model is loaded
    if curl -sSf http://localhost:11434/api/tags | grep -q "llama3.1"; then
        echo "Ollama service is ready with model llama3.1."
        break
    fi

    # Check if timeout is exceeded
    CURRENT_TIME=$(date +%s)
    if [ $((CURRENT_TIME - START_TIME)) -ge $TIMEOUT ]; then
        echo "PrivateGPT server failed to start within $TIMEOUT seconds"
        exit 1
    fi

    # Log progress and retry
    echo "Server not yet available. Retrying in 10 seconds... (Attempt $RETRY_COUNT of $MAX_RETRIES)"
    sleep 10
done
echo "Setup complete. Fully local environment is ready."