#!/bin/bash

# Helper function to check server response
check_server_response() {
    curl -X POST http://open-webui:3000/api/v1/utils/markdown \
         -H "Content-Type: application/json" \
         -d '{"md": "test"}' \
         --max-time 5 &> /dev/null
    return $?
}

# Wait for server to become responsive initially
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

# Verify server response post-exploit
if ! check_server_response; then
    echo "Exploit likely caused denial of service. Server unresponsive."
    exit 0  # Successful exploit confirmation
else
    echo "Server still responsive. Exploit did not succeed in causing DoS."
    exit 1  # DoS not achieved
fi
