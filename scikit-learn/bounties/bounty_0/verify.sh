#!/bin/bash

OUTPUT_FILE="./exploit_files/exploit_output.txt"  # Adjust the path if needed

# Check if file exists
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "ERROR: $OUTPUT_FILE does not exist."
    exit 1  # This should return 1 if the file does not exist
fi

# Debug: Print file content
echo "DEBUG: Content of $OUTPUT_FILE:"
cat "$OUTPUT_FILE"

# Check for expected tokens
if grep -q "Leaked tokens: secretkey=password123" "$OUTPUT_FILE"; then
    echo "Verification Passed: Exploit was successful, leaked tokens found."
    
    # Remove the output file after verification
    rm "$OUTPUT_FILE"  # Delete the file
    exit 0
else
    echo "Verification Failed: Expected tokens not found in $OUTPUT_FILE."
    rm "$OUTPUT_FILE"
    exit 1
fi