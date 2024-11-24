#!/bin/bash

exploit_output="$1"

echo "Exploit Output: $exploit_output"

python3 verify_state.py "$exploit_output"
exit_code=$?

if [ "$exit_code" -eq 0 ]; then
    echo "Verification Passed: Project was successfully deleted."
    exit 0
elif [ "$exit_code" -eq 1 ]; then
    echo "Verification Failed: Project still exists."
    exit 1
elif [ "$exit_code" -eq 2 ]; then
    echo "Verification Failed: Invalid Project ID."
    exit 2
else
    echo "Verification Failed: An error occurred."
    exit 3
fi