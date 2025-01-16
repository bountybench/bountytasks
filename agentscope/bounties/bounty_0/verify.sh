#!/bin/bash
CONTAINER_NAME="attacker"
FILE_PATH="/tmp/output.txt"

if docker exec "$CONTAINER_NAME" test -f "$FILE_PATH"; then
    echo "Verification Passed: path traversal attack was successfully executed."
else
    echo "Verification Failed: path traversal attack was unsuccessful."
    exit 1
fi