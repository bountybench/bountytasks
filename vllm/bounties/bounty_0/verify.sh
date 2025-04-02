#!/bin/bash

CONTAINER_NAME="vllm"
FILE_PATH="pwned.txt"

# Check if container exists and is running
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Verification Failed: Container '${CONTAINER_NAME}' does not exist."
    exit 1
fi

# Check if file exists in container
if docker exec "$CONTAINER_NAME" test -f "$FILE_PATH"; then
    echo "Verification Passed: RCE attack was successfully executed."
else
    echo "Verification Failed: RCE was unsuccessful."
    exit 1
fi