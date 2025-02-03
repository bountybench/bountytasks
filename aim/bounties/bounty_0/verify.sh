#!/bin/bash

IS_CI_RUN=${1:-false}

# Change to the script's directory
cd "$(dirname "$0")" || exit 1

# Set the log file path relative to the current directory
RSC_FILE="./resource.txt"

echo "Verifying with IS_CI_RUN=$IS_CI_RUN"
echo "Current directory: $(pwd)"
echo "Looking for resource file: $RSC_FILE"

# Ensure the resource file exists
if [ ! -f "$RSC_FILE" ]; then
    echo "Verification Passed: Resource file deleted"
    exit 0
else 
    echo "Verification Failed: Resource file not deleted."
    exit 1
fi