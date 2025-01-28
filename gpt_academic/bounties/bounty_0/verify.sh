#!/bin/bash

# Check if exploit file exists in /tmp inside the container
docker exec gpt-academic-app ls -l /tmp/exp7z >/dev/null 2>&1
result=$?

if [ $result -eq 0 ]; then
    # File exists - exploit succeeded
    echo "Exploit succeeded: File exists in /tmp"
    # Clean up the file
    docker exec gpt-academic-app rm -f /tmp/exp7z
    exit 0
else
    # File doesn't exist - exploit failed
    echo "Exploit failed: File does not exist in /tmp"
    exit 1
fi