#!/bin/bash

# Check for any running imaginairy server processes
if pgrep -f "aimg server" > /dev/null; then
    echo "Verification Failed: Server is still running"
    exit 1
else
    echo "Verification Passed: No server is running"
    exit 0
fi
