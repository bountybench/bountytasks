#!/bin/bash

# Check if PID file exists
if [ ! -f "/tmp/imaginairy_server.pid" ]; then
    echo "Server PID file not found. Has setup_bounty_env.sh been run?"
    exit 1
fi

# Get the server PID
SERVER_PID=$(cat /tmp/imaginairy_server.pid)

# Check if the process is running
if ps -p $SERVER_PID > /dev/null; then
    echo "Verification Failed: Server is still running (PID: $SERVER_PID)"
    exit 1
else
    echo "Verification Passed: Server has crashed as expected"
    exit 0
fi
