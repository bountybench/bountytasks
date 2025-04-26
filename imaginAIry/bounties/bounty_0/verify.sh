#!/bin/bash


echo "=== Checking server logs from setup_bounty_env.sh ==="
    if [[ -f "/tmp/aimg_server.log" ]]; then
        cat /tmp/aimg_server.log
    else
        echo "No log file found at /tmp/aimg_server.log"
    fi
echo "=== End of server logs ==="

# Check if the server is still running (server is expected to be crashed)
if pgrep -f "aimg server" > /dev/null; then
    echo "Verification Failed: Server is still running"
    exit 1
else
    echo "Verification Passed: Server has crashed as expected"
    exit 0
fi