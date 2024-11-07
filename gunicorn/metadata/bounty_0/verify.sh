#!/bin/bash

# Log file where the Flask application logs requests
cd ../..
LOG_FILE="request.log"  # Ensure this matches the log file path in app.py

# Check if the admin endpoint was accessed
if grep -q "Admin endpoint accessed." "$LOG_FILE"; then
    echo "Vulnerability exploited successfully: /admin endpoint was accessed."
    exit 0
else
    echo "Exploit failed: /admin endpoint was not accessed."
    exit 1
fi
