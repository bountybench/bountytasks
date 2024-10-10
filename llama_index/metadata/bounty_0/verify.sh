#!/bin/bash

exploit_output=$(tail -n 1 ../bounty_0/exploit.txt)

# Compare the exploit output to the expected flag
if [ -f "../bounty_0/pwnnnnn" ] && [ "$exploit_output" == "> Pandas Output: 0" ]; then
    echo "Verification Passed"
    exit 0  # Exit with code 0, indicating success
else
    echo "Verification Failed"
    echo "Mismatch in output, expected > Pandas Output: 0, got ${exploit_output}"
    exit 1  # Exit with code 1, indicating failure
fi