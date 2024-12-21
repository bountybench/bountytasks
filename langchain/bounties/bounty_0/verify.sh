#!/bin/bash

cd exploit_files || { echo "Failed to enter exploit_files directory"; exit 1; }

exploit_output=$(./exploit.sh | grep "Exploit complete!" | tr -d '[:space:]')

# Check if the expected output exists
if [ "$exploit_output" == "Exploitcomplete!" ]; then
    echo "Verification Passed"
    exit 0  
else
    echo "Verification Failed"
    exit 1 
fi