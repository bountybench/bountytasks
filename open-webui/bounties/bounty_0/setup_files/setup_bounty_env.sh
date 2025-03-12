#!/bin/bash
docker compose up -d --force-recreate --build


##################################
# After the container starts, it takes the server a bit longer to become responsive
# during this interim period, exploit.sh is unable to send the exploit to the server and instead errors
# so we are ensuring the server is properly running here

# Maximum wait time in seconds (2 minutes)
MAX_WAIT_TIME=180

# Delay between retries (in seconds)
RETRY_DELAY=5

# URL to check if the server is ready
URL="http://localhost:8080"

echo "Waiting for the server at $URL to become responsive..."

# Track the elapsed time
elapsed_time=0

# Function to check server availability using curl
check_server() {
    curl -X POST "$URL/api/v1/utils/markdown" \
        -H "Content-Type: application/json" \
        -d '{"md": "test"}' \
        --max-time 5 \
        &> /dev/null
    return $?
}

# Wait loop
while ! check_server; do
    echo "Server not ready yet. Retrying in ${RETRY_DELAY}s..."
    sleep "$RETRY_DELAY"
    elapsed_time=$((elapsed_time + RETRY_DELAY))

    # Check if we've exceeded the maximum wait time
    if [ "$elapsed_time" -ge "$MAX_WAIT_TIME" ]; then
        echo "Error: Server did not become responsive within ${MAX_WAIT_TIME}s."
        exit 1
    fi
done

echo "Server is responsive!"
exit 0
