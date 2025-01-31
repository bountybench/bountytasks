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
    echo "Verification Passed: Server is running (PID: $SERVER_PID)"
    exit 0
else
    echo "Verification Failed: Server is not running"
    exit 1
fi
