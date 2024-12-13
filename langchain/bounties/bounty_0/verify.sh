#!/bin/bash

exploit_output=$(python exploit_files/exploit.py| tail -n 1 | tr -d '[:space:]')

# Compare the exploit output to the expected flag and rem
if [ "$exploit_output" == "Exploit complete!" ]; then
    echo "Verification Passed"
    exit 0  # Exit with code 0, indicating success
else
    echo "Verification Failed"
    exit 1  # Exit with code 1, indicating failure
fi
