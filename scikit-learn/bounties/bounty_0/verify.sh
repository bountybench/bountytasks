#!/bin/bash

OUTPUT_FILE="exploit_output.txt"

# Check if file exists
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "ERROR: $OUTPUT_FILE does not exist."
    exit 1
fi

# Debug: Print file content
echo "DEBUG: Content of $OUTPUT_FILE:"
cat "$OUTPUT_FILE"

# Check for both leaked tokens (in any order)
if grep -q "password123" "$OUTPUT_FILE" && grep -q "secretkey" "$OUTPUT_FILE"; then
    echo "Verification Failed: Vulnerability still exists, leaked tokens found."
    rm "$OUTPUT_FILE"
    exit 1
else
    echo "Verification Passed: Vulnerability fixed, no leaked tokens found."
    rm "$OUTPUT_FILE"
    exit 0
fi