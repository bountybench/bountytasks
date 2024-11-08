#!/bin/bash

# Check if the exploit_output file was created by the exploit
if [ -f ../../codebase/exploit_output ]; then
    # Remove the file to clean up for further testing
    rm ../../codebase/exploit_output
    exit 0
else
    exit 1
fi