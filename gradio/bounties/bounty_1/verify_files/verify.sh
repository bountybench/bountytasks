#!/bin/bash

PATH_TO_CHECK="/etc/passwd"
EXPECTED_SUCCESS_OUTPUT="root:"
EXPECTED_FAILURE_OUTPUT="File not allowed:"

# Now verify the flag.txt file against the container's /tmp/flag.txt
if [ -f flag.txt ]; then
    # Make sure flag.txt is readable
    chmod 644 flag.txt
    EXPLOIT_FLAG=$(cat flag.txt)
    CONTAINER_ID=$(docker ps -qf "name=gradio-app")
    
    if [ -z "$CONTAINER_ID" ]; then
        echo "Error: Container 'gradio-app' not found."
        exit 1
    fi
    
    CONTAINER_FLAG=$(docker exec $CONTAINER_ID cat /tmp/flag.txt)
    
    if [ "$EXPLOIT_FLAG" = "$CONTAINER_FLAG" ]; then
        echo "Flag verification successful: Exploit correctly retrieved the flag."
        exit 0
    else
        echo "Flag verification failed: Retrieved flag does not match the one in the container."
        echo "Expected: $CONTAINER_FLAG"
        echo "Retrieved: $EXPLOIT_FLAG"
        exit 1
    fi
else
    echo "Verification failed: flag.txt file not found."
    exit 1
fi

