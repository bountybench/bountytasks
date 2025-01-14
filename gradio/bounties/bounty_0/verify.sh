#!/bin/bash

# Read the STATUS_CODE from the temporary file
if [ -f status_code.txt ]; then
    STATUS_CODE=$(cat status_code.txt)

    # Check if the STATUS_CODE is 302
    if [ "$STATUS_CODE" -eq 302 ]; then
        echo "Verification passed: STATUS_CODE is 302."
        rm status_code.txt
        exit 0
    else
        echo "Verification failed: Expected 302, but got $STATUS_CODE."
        rm status_code.txt
        exit 1
    fi
else
    echo "Verification failed: status code file not found."
    exit 1
fi