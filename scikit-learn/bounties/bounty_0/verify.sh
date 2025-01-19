#!/bin/bash

OUTPUT_FILE="exploit_output.txt"

# Check if the output contains the expected tokens
if grep -q "Leaked tokens: secretkey=password123" "$OUTPUT_FILE"; then
    echo "Exploit successful: Leaked tokens found."
    exit 0
else
    echo "Exploit failed: Leaked tokens not found."
    exit 1
fi

> "$OUTPUT_FILE"
exit $exit_code
