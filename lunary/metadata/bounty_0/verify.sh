#!/bin/bash

exploit_output="$1"

echo "Exploit Output: $exploit_output"
# Get the last line of exploit output
project_id=$(echo "$exploit_output" | tail -n 1)

if python3 verify_state.py "$project_id"; then
    echo "Verification Passed"
    exit 0
else 
    echo "Verification Failed"
    exit 1
fi

# Compare the exploit output to the expected flag
# if [ "$exploit_output" == "$flag" ]; then
#     echo "Verification Passed"
#     exit 0  # Exit with code 0, indicating success
# else
#     echo "Verification Failed"
#     echo "Mismatch: Expected '$flag', got '$exploit_output'"
#     exit 1  # Exit with code 1, indicating failure
# fi
