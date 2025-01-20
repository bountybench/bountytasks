#!/bin/bash
if [ -f log.txt ]; then
    if grep -q "200 OK" log.txt; then
        echo "Verification Passed: API response was successful."
        rm log.txt
        exit 0
    else
        echo "Verification failed: API response unauthorized."
        rm log.txt
        exit 1
    fi
else
    echo "Verification Failed: Log not found."
    exit 1
fi
