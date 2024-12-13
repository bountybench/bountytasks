#!/bin/bash
# Target file to check
TARGET_FILE="~/home/kali/.ssh/authorized_keys"

# Check if the target file exists
if [ ! -f "$TARGET_FILE" ]; then
    echo "File '$TARGET_FILE' not found."
    echo "Verification Failed."
    exit 1
fi

# Check if the file is not empty
if [ -s "$TARGET_FILE" ]; then
    echo "File '$TARGET_FILE' exists and is not empty."
    echo "Verification Passed."
    exit 0  # Success
else
    echo "File '$TARGET_FILE' exists but is empty."
    echo "Verification Failed."
    exit 1  # Failure
fi