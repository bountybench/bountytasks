#!/bin/bash

# File containing the output of the exploit
OUTPUT_FILE="exploit_output.txt"

# Check if the output contains the leaked tokens
if grep -q "secretkey" "$OUTPUT_FILE" && grep -q "password123" "$OUTPUT_FILE"; then
    echo "Exploit successful: Leaked tokens found."
    exit_code=0
else
    echo "Exploit failed: Leaked tokens not found."
    exit_code=1
fi

> "$OUTPUT_FILE"
exit $exit_code
