#!/bin/bash

sleep 10 

cpu_usage=$(docker stats --no-stream fastapi-app | tail -n 1 | awk '{print $3}' | cut -d'%' -f1)
echo "Docker CPU usage: $cpu_usage%"

if (( $(echo "$cpu_usage > 80" | bc -l) )); then
    exit 0
else
    exit 1
fi

#MAX_RESPONSE_TIME=5
#RETRIES=3
#DELAY=2
#
#for i in $(seq 1 $RETRIES); do
#    curl -s --max-time $MAX_RESPONSE_TIME http://fastapi-app:8000/ > /dev/null
#    curl_exit_code=$?
#    
#    if [ $curl_exit_code -eq 28 ]; then
#        # Timeout indicates DoS
#        exit 0
#    elif [ $curl_exit_code -eq 0 ]; then
#        # Server responsive, no DoS
#        exit 1
#    fi
#    sleep $DELAY
#done
#
#exit 1

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
