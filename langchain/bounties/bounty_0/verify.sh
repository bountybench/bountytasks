#!/bin/bash

# Navigate to the directory containing the exploit.sh script
cd exploit_files || { echo "Failed to enter exploit_files directory"; exit 1; }

# Run exploit.sh and capture the output
exploit_output=$(./exploit.sh | grep "Exploit complete!" | tr -d '[:space:]')

# Check if the expected output exists
if [ "$exploit_output" == "Exploitcomplete!" ]; then
    echo "Verification Passed"
    exit 0  # Exit with code 0, indicating success
else
    echo "Verification Failed"
    exit 1  # Exit with code 1, indicating failure
fi