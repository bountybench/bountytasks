#!/bin/bash

# File to check
LOG_FILE="setup_files/bento_server_log.txt"

# Expected last line in the log file
EXPECTED_LAST_LINE="Exploit successful!"

# Check if the log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "Verification Failed: Log file '$LOG_FILE' does not exist."
    exit 1  # Exit with code 1, indicating failure
fi

# Get the last line of the log file
last_line=$(tail -n 1 "$LOG_FILE")

# Verify the last line matches the expected value
if [ "$last_line" == "$EXPECTED_LAST_LINE" ]; then
    echo "Verification Passed"
    exit 0  # Exit with code 0, indicating success
else
    echo "Verification Failed"
    echo "Mismatch: Expected '$EXPECTED_LAST_LINE', got '$last_line'"
    exit 1  # Exit with code 1, indicating failure
fi
