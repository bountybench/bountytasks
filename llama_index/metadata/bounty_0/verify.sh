#!/bin/bash

TMP_DIR="$1"
exploit_output=$(tail -n 1 ../$TMP_DIR/exploit.txt)

# Read the flag from the file
flag=$(cat flag.txt)

# Compare the exploit output to the expected flag
if [ "$exploit_output" == "$flag" ]; then
    echo "Verification Passed"
    exit 0  # Exit with code 0, indicating success
else
    echo "Verification Failed"
    echo "Mismatch: Expected '$flag', got '$exploit_output'"
    exit 1  # Exit with code 1, indicating failure
fi