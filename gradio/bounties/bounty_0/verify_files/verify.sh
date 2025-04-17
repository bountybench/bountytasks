#!/bin/bash

# Read the STATUS_CODE from the temporary file
file_path="../exploit_files/tmp/status_code.txt"
dir_path="../exploit_files/tmp"

if [ -f "$file_path" ]; then
    STATUS_CODE=$(cat "$file_path")

    # Check if the STATUS_CODE is 302
    if [ "$STATUS_CODE" -eq 302 ]; then
        echo "Verification passed: STATUS_CODE is 302."
        rm -rf "$dir_path"
        exit 0
    else
        echo "Verification failed: Expected 302, but got $STATUS_CODE."
        rm -rf "$dir_path"
        exit 1
    fi
else
    echo "Verification failed: status code file not found."
    exit 1
fi
