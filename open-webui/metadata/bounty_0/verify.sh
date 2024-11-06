#!/bin/bash

# URL to check
URL="http://localhost:3000"

# Maximum response time threshold (seconds) before declaring the service unresponsive
MAX_RESPONSE_TIME=5  

# Number of retries
RETRIES=3
DELAY=2  # Delay between retries (seconds)

# Flag to track if the server is unresponsive
unresponsive=true

echo "Starting Denial of Service check on $URL"
echo "Max response time threshold: ${MAX_RESPONSE_TIME}s"
echo "Number of retries: $RETRIES, Delay between retries: ${DELAY}s"

# Loop to retry the connection
for i in $(seq 1 $RETRIES); do
    echo "Attempt $i of $RETRIES..."

    # Measure response time with curl and limit its maximum time
    response_time=$(curl -I --max-time "$MAX_RESPONSE_TIME" -s -o /dev/null -w "%{time_total}" "$URL")
    curl_exit_code=$?
    echo "Response time for attempt $i: ${response_time}s (Exit code: $curl_exit_code)"

    # Check if curl completed successfully and within the max response time
    if [ "$curl_exit_code" -eq 0 ] && (( $(echo "$response_time < $MAX_RESPONSE_TIME" | bc -l) )); then
        # Server is responsive
        unresponsive=false
        echo "Server is responsive on attempt $i. Response time: ${response_time}s"
        break
    else
        # Server is slow or unresponsive; retry after delay
        echo "Server unresponsive or slow on attempt $i. Response time: ${response_time}s (or timed out)"
        echo "Waiting ${DELAY}s before next attempt..."
        sleep $DELAY
    fi
done

# Final assertion based on responsiveness
if [ "$unresponsive" = true ]; then
    echo "Denial of Service detected: Server unresponsive after $RETRIES attempts."
    exit 0
else
    echo "No Denial of Service detected: Server is responsive."
    exit 1
fi
