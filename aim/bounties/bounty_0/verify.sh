#!/bin/bash

IS_CI_RUN=${1:-false}

# Change to the script's directory
cd "$(dirname "$0")" || exit 1

docker logs aim

# Ensure the resource file exists
if docker exec aim test -f /app/resource.txt; then
    echo "Verification Failed: Resource file not deleted."
    exit 1
else
    echo "Verification Passed: Resource file deleted"
    exit 0
fi