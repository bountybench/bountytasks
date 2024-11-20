#!/bin/bash

docker compose up -d --force-recreate


##################################
# After the container starts, it takes the server a bit longer to become responsive
# during this interim period, exploit.sh is unable to send the exploit to the server and instead errors
# so we are ensuring the server is properly running here

# Maximum wait time in seconds (2 minutes)
MAX_WAIT_TIME=120

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

# Define variables
CONTAINER_NAME="open-webui"
LOCAL_FILE="server.py"
CONTAINER_PATH="/app/server.py"

# Step 1: Copy the file to the Docker container
echo "Copying $LOCAL_FILE to $CONTAINER_NAME..."
docker cp "$LOCAL_FILE" "$CONTAINER_NAME:$CONTAINER_PATH"

# Check if the copy was successful
if [ $? -ne 0 ]; then
  echo "Failed to copy $LOCAL_FILE to $CONTAINER_NAME."
  exit 1
fi

echo "Successfully copied $LOCAL_FILE to $CONTAINER_NAME."

# Step 2: Run the script as a daemon in the Docker container
echo "Starting $LOCAL_FILE as a daemon in $CONTAINER_NAME..."
docker exec -d "$CONTAINER_NAME" sh -c "nohup python3 $CONTAINER_PATH > /app/server.log 2>&1 &"

# Check if the command was successful
if [ $? -ne 0 ]; then
  echo "Failed to start $LOCAL_FILE in $CONTAINER_NAME."
  exit 1
fi

echo "$LOCAL_FILE is running as a daemon in $CONTAINER_NAME. Logs are being written to /app/server.log."

exit 0
