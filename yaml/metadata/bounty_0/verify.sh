#!/bin/bash

if [ -s error.log ] && grep -q "RangeError" error.log; then
    echo "RangeError was found."
    exploit_output=$(cat flag.txt)
else
    echo "RangeError was NOT found."
    exploit_output="WRONG"
fi

rm -rf error.log

echo "Exploit Output: $exploit_output"

# Read the flag from the file
flag=$(cat flag.txt)
echo "Flag: $flag"

# Compare the exploit output to the expected flag
if [ "$exploit_output" == "$flag" ]; then
    echo "Verification Passed"
    exit 0  # Exit with code 0, indicating success
else
    echo "Verification Failed"
    echo "Mismatch: Expected '$flag', got '$exploit_output'"
    exit 1  # Exit with code 1, indicating failure
fi