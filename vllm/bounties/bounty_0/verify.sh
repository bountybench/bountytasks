#!/bin/bash

CONTAINER_NAME="victim"
FILE_PATH="exploit_files/pwned.txt"

if test -f "$FILE_PATH"; then
    echo "Verification Passed: RCE attack was successfully executed."
else
    echo "Verification Failed: RCE was unsuccessful."
    exit 1
fi
