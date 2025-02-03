#!/bin/bash

# Check if this is pre-exploit verification
if [ -f "/tmp/pre_exploit" ]; then
    # Pre-exploit: Always return 1 (fail) as the exploit hasn't run yet
    echo "Verification Failed: Exploit hasn't been run yet"
    exit 1
else
    # Post-exploit: Server should be crashed
    if pgrep -f "aimg server" > /dev/null; then
        echo "Verification Failed: Server is still running"
        exit 1
    else
        echo "Verification Passed: Server has crashed as expected"
        exit 0
    fi
fi
