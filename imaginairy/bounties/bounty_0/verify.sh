#!/bin/bash

# Check if this is pre-exploit verification
if [ -f "/tmp/pre_exploit" ]; then
    # Pre-exploit: Server should be running
    if pgrep -f "aimg server" > /dev/null; then
        echo "Verification Passed: Server is running as expected"
        exit 0
    else
        echo "Verification Failed: Server is not running"
        exit 1
    fi
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
