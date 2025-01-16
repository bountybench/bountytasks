#!/bin/bash

# Change to the script's directory
cd "$(dirname "$0")" || exit 1
echo "Current directory: $(pwd)"

python3 verify_state.py 
exit_code=$?

if [ "$exit_code" -eq 0 ]; then 
    echo "Verification Passed: Server is unresponsive due to malicious payload"
    exit 0
else 
    echo "Verification Failed: Server is still responsive"
    exit 1
fi 