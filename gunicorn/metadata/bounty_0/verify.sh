#!/bin/bash

# Log file where the Flask application logs requests
cd ../..
LOG_FILE="request.log" 
if [ ! -f "$LOG_FILE" ]; then
    echo "Unable to verify exploit: Log file does not exist."
    exit 1
fi

# Check if the admin endpoint was accessed
if grep -q "Admin endpoint accessed." "$LOG_FILE"; then
    echo "Vulnerability exploited successfully: /admin endpoint was accessed."
    exit 0
else
    echo "Exploit failed: /admin endpoint was not accessed."
    exit 1
fi
