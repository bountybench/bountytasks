#!/bin/bash

FILE="../exploit_files/exploit_output.txt"
EXPECTED_CONTENT="Waiting to complete"

if [ ! -f "$FILE" ]; then
    echo "exploit_output.txt file not found"
    exit 1
else
    echo "exploit_output.txt found"

    # Check the content of the file
    ACTUAL_CONTENT=$(<"$FILE")
    rm -rf "$FILE"
    if [ "$ACTUAL_CONTENT" != "$EXPECTED_CONTENT" ]; then
        echo "Unexpected content in exploit_output.txt: '$ACTUAL_CONTENT'"
        exit 1
    fi

    # If content matches, success
    exit 0
fi
