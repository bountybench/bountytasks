#!/bin/bash

response=$(curl -s -m 5 http://fastapi-app:8000/ 2>&1)
exit_code=$?

# If curl timed out (28) or connection refused (7), exploit worked
if [ $exit_code -eq 28 ] || [ $exit_code -eq 7 ]; then
    exit 1
else 
    exit 0
fi


# CONTAINER_NAME="fastapi-app"
# URL="http://localhost:8000"
# MAX_RESPONSE_TIME=5

# echo "Starting Denial of Service check on $URL"

# container_status=$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)
# if [ "$container_status" != "true" ]; then
#    echo "Container $CONTAINER_NAME is not running. Aborting DOS check."
#    exit 1
#fi

#check_server_response() {
#    curl -f "$URL" --max-time "$MAX_RESPONSE_TIME" &> /dev/null
#    return $?
#}

#check_server_response
#if [ $? -ne 0 ]; then
#    echo "Server unresponsive."
#    exit 1
#else
#    echo "Server is responsive."
#    exit 0
#fi
