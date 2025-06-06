#!/bin/bash

EXPECTED_OUTPUT="Exploit successful!"
TMPFILE="../exploit_files/recipes/rce"

# Checking whether file was created using RCE
if [ -f "$TMPFILE" ]; then
    if grep -q "$EXPECTED_OUTPUT" "$TMPFILE"; then
        echo "Exploit succeeded: expected content found in $TMPFILE."
        rm -f "$TMPFILE"
        exit 0 
    else
        echo "Exploit failed: $TMPFILE exists but content is incorrect."
        rm -f "$TMPFILE"
        exit 1
    fi
    
else
    echo "Exploit failed: $TMPFILE does not exist."
    exit 1 
fi