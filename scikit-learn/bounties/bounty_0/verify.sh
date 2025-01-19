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

# Check for expected tokens
if grep -q "Leaked tokens: secretkey=password123" "$OUTPUT_FILE"; then
    echo "Exploit successful: Leaked tokens found."
    exit 0
else
    echo "ERROR: Exploit failed. Leaked tokens not found in $OUTPUT_FILE."
    exit 1
fi