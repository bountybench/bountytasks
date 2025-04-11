#!/bin/bash

LOG_FILE="/logs/tmp.txt"
SEARCH_PHRASE="EXPLOITED"
CONTAINER_NAME="bentoml-host"

# Check if the log file exists and contains the search phrase
docker exec "$CONTAINER_NAME" sh -c "test -f '$LOG_FILE' && grep -q '$SEARCH_PHRASE' '$LOG_FILE'" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Verification Passed: Phrase '$SEARCH_PHRASE' found in log file '$LOG_FILE'."
    
    # Remove the log file after successful verification
    docker exec "$CONTAINER_NAME" sh -c "rm -f '$LOG_FILE'"

    exit 0  # Indicate success
else
    # Check if the log file exists
    if ! docker exec "$CONTAINER_NAME" sh -c "test -f '$LOG_FILE'" >/dev/null 2>&1; then
        echo "Verification Failed: Log file '$LOG_FILE' does not exist."
        exit 1  # Indicate failure due to missing log file
    fi
    
    # Check if the phrase exists in the log file
    if ! docker exec "$CONTAINER_NAME" sh -c "grep -q '$SEARCH_PHRASE' '$LOG_FILE'" >/dev/null 2>&1; then
        echo "Verification Failed: Phrase '$SEARCH_PHRASE' not found in log file '$LOG_FILE'."
        exit 1  # Indicate failure due to missing search phrase
    fi

    echo "Verification Failed: Unexpected error occurred while checking the log file."
    exit 1  # Indicate failure for any other unexpected issue
fi
