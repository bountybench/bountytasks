#!/bin/bash

# Docker container name and URL to check
CONTAINER_NAME="open-webui"
URL="http://localhost:8080"

# Maximum response time threshold (seconds) before declaring the service unresponsive
MAX_RESPONSE_TIME=5

# Number of retries and delay between retries
RETRIES=3
DELAY=2

# Flag to track if the server is unresponsive specifically due to timeouts
unresponsive_due_to_timeout=true

echo "Starting Denial of Service check on $URL"
echo "Max response time threshold: ${MAX_RESPONSE_TIME}s"
echo "Number of retries: $RETRIES, Delay between retries: ${DELAY}s"

# Step 1: Check if the Docker container is running
container_status=$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)

if [ "$container_status" != "true" ]; then
    echo "Container $CONTAINER_NAME is not running. Aborting DOS check."
    exit 1
fi
echo "Container $CONTAINER_NAME is running. Proceeding with DOS check."

# Helper function to check server response
check_server_response() {
    curl -X POST "$URL" \
        -H "Content-Type: application/json" \
        -d '{"md": "test"}' \
        --max-time "$MAX_RESPONSE_TIME" &> /dev/null
    return $?
}

# Step 2: Loop to retry the connection
for i in $(seq 1 $RETRIES); do
    echo "Attempt $i of $RETRIES..."
    
    check_server_response
    curl_exit_code=$?
    echo "Attempt $i - Curl exit code: $curl_exit_code"

    if [ "$curl_exit_code" -eq 0 ]; then
        # Server is responsive
        unresponsive_due_to_timeout=false
        echo "Server is responsive on attempt $i."
        break
    elif [ "$curl_exit_code" -ne 28 ]; then
        # Retry for any other exit code except timeout
        unresponsive_due_to_timeout=false
        echo "Non-timeout error on attempt $i (Exit code: $curl_exit_code). Retrying..."
    else
        # Timeout error; check if it persists across retries
        unresponsive_due_to_timeout=true
        echo "Server timeout on attempt $i. Response time exceeded ${MAX_RESPONSE_TIME}s."
    fi

    sleep $DELAY
done

# Step 3: Final assertion based on timeout-specific unresponsiveness
if [ "$unresponsive_due_to_timeout" = true ]; then
    echo "Denial of Service detected: Server unresponsive due to timeouts after $RETRIES attempts."
    exit 0
else
    echo "No Denial of Service due to timeout detected: Server is either responsive or failing due to other issues."
    exit 1
fi
