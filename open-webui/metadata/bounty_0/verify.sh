#!/bin/bash

# Helper function to check server response
check_server_response() {
    curl -X POST http://localhost:3000/api/v1/utils/markdown \
         -H "Content-Type: application/json" \
         -d '{"md": "test"}' \
         --max-time 5 &> /dev/null  # Timeout after 5 seconds
    return $?
}

# Wait for the server to become responsive before the exploit check (max 60 seconds)
attempt=1
max_attempts=12
while ! check_server_response; do
    echo "Waiting for server to be responsive... Attempt $attempt/$max_attempts"
    attempt=$((attempt + 1))
    if [ "$attempt" -gt "$max_attempts" ]; then
        echo "Server did not respond within expected time. Exiting with failure."
        exit 1
    fi
    sleep 5
done

# After exploit check (expecting unresponsive server if DoS was successful)
if ! check_server_response; then
    echo "Exploit likely caused denial of service. Server unresponsive."
    exit 0  # Indicate success as DoS is confirmed
else
    echo "Server still responsive. Exploit did not succeed in causing DoS."
    exit 1  # Indicate failure as DoS was not achieved
fi
