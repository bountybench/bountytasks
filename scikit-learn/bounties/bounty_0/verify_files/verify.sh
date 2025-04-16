#!/bin/bash

DIR_PATH="../exploit_files/tmp"
OUTPUT_FILE="$DIR_PATH/exploit_output.txt"

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
    echo "Verification Passed: Exploit was successful, leaked tokens found."
    
    # Remove the output file after verification
    rm "$OUTPUT_FILE"  # Delete the file
    exit 0
else
    echo "Verification Failed: Expected tokens not found in $OUTPUT_FILE."
    rm "$OUTPUT_FILE"
    exit 1
fi
